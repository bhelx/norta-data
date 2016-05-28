defmodule Norta.Feed.Fetcher do
  use GenServer, otp_app: :norta
  use Timex
  require Logger
  alias Norta.Feed.Parser

  @default_feed_rate 4_000 # every 4 seconds

  @service_endpoint "http://gpsinfo.norta.com/"
  @service_headers [{"Connection", "keep-alive"}]

  @epoch_offset Druuid.epoch_offset({{2016, 1, 1}, {0, 0, 0}})

  def start_link do
    initial_state = %{
      response_hash: nil,
      stales: %{}
    }
    GenServer.start_link(__MODULE__, initial_state, name: :feed_fetcher)
  end

  def init(state) do
    Logger.info "Starting Fetcher"
    set_timer 0 # run immediately
    {:ok, state}
  end

  def handle_info(:fetch, state) do
    {state, retry_time} = fetch_vehicles |> handle_response(state)
    set_timer retry_time
    {:noreply, state}
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, state) do
    hash = :crypto.hash(:md5, body)

    if state[:response_hash] == hash do
      Logger.info "md5 matched #{Base.encode64(hash)}"
      notify_server_response(:md5_match)
    else
      # will return nil if there was a problem
      vehicles = parse_response(body)

      if vehicles do
        Logger.info "Found #{length(vehicles)} vehicles with hash #{Base.encode64(hash)}"

        # Find new vehicles marked as stale
        marked_stale =
          vehicles
          |> Enum.filter(fn v -> v[:stale] end)
          |> Enum.map(fn v -> {v[:name], v} end)
          |> Enum.into(%{})

        IO.inspect("marked stale")
        IO.inspect(length(Map.keys(marked_stale)))
        IO.inspect(Map.keys(marked_stale))

        # Merge them in
        stales = Map.merge(state[:stales], marked_stale)

        # Look for any non stale vehicles that may have been mis-labeled
        # as non-stale and replace them with our persisted vehicles which
        # we know to have the correct datetime
        fixed_vehicles =
          vehicles
          |> Enum.map(fn v ->
            candidate = stales[v[:name]]
            if candidate && vehicles_equal(v, candidate) do
              candidate
            else
              v
            end
          end)

        state = %{state | stales: stales}

        notify_server_response(:success)
        notify_vehicles(fixed_vehicles)
      else # there was a problem parsing the vehicles, should send an event
        #TODO send event
      end
    end

    state = %{state | response_hash: hash}

    Logger.debug("Fetcher State: #{inspect state}")

    {state, @default_feed_rate}
  end

  def handle_response({:error, %HTTPoison.Error{id: id, reason: reason}}, state) do
    Logger.info "Fetch failed with {#{inspect id}, #{inspect reason}} trying again in 2 seconds"
    {state, 1_000} # Try again in 1 second
  end

  defp fetch_vehicles do
    HTTPoison.get(@service_endpoint, @service_headers, [params: norta_service_params])
  end

  defp norta_service_params do
    %{key: Application.fetch_env!(:norta, :api_key)}
  end

  defp set_timer(time \\ @default_feed_rate) do
    Process.send_after(self(), :fetch, time)
  end

  defp notify_vehicles(vehicles) do
    notify_feed(:vehicles, %{vehicles: vehicles})
  end

  defp notify_server_response(code) do
    notify_feed(:server_response, %{code: code})
  end

  defp notify_feed(event, payload) do
    # insert event id
    payload = Map.put(payload, :event_id, Druuid.gen(@epoch_offset))

    # send to the event stream
    Norta.Feed.EventManager.notify(event, payload)
  end

  defp vehicles_equal(v1, v2) do
    v1[:name] == v2[:name] &&
    v1[:speed] == v2[:speed] &&
    v1[:route] == v2[:route] &&
    v1[:lat] == v2[:lat] &&
    v1[:lng] == v2[:lng] &&
    v1[:bearing] == v2[:bearing]
    v1[:train] == v2[:train]
  end

  defp parse_response(body) do
    try do
      Parser.parse_vehicles(body)
    catch
      _ ->
        Logger.info("Got Fetcher error")
        nil
    end
  end

end
