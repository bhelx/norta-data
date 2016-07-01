defmodule Norta.Feed.LoggingHandler do
  use GenEvent, otp_app: :norta
  require Logger
  alias Norta.Repo
  alias Norta.ServerResponse
  alias Norta.Vehicle

  def handle_event({:server_response, payload}, state) do
    Logger.info("Got server response #{payload[:code]}")
    server_response_for(payload)
    |> Repo.insert!

    {:ok, state}
  end
  def handle_event({:vehicles, payload}, state) do
    Logger.info("Got vehicles event")

    payload[:vehicles]
    |> Enum.map(fn vehicle_map ->
      Map.put(vehicle_map, :event_id, payload[:event_id])
    end)
    |> Enum.map(&Vehicle.from_map/1)
    |> Enum.each(fn changeset ->
      case Repo.insert(changeset) do
        {:ok, model} ->
          Logger.debug("Wrote model")
        {:error, changset} ->
          Logger.info("Error writing vehicle: #{inspect changeset.errors}")
          Logger.info(inspect changeset)
      end
    end)

    {:ok, state}
  end

  def server_response_for(payload = %{code: :md5_match}) do
    %ServerResponse{
      md5_match: true,
      xml_valid: true,
      status_code: 200,
      response_valid: true,
      event_id: payload[:event_id]
    }
  end
  def server_response_for(payload = %{code: :success}) do
    %ServerResponse{
      md5_match: false,
      xml_valid: true,
      status_code: 200,
      response_valid: true,
      inserted_at: payload[:event_datetime],
      event_id: payload[:event_id]
    }
  end
  def server_response_for(payload = %{code: :invalid_xml}) do
    %ServerResponse{
      md5_match: false,
      xml_valid: false,
      status_code: 200,
      response_valid: false,
      inserted_at: payload[:event_datetime],
      event_id: payload[:event_id]
    }
  end
end
