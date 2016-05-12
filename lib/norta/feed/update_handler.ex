defmodule Norta.Feed.UpdateHandler do
  use GenEvent, otp_app: :norta

  import Norta.Endpoint, only: [broadcast: 3]

  def vehicles do
    GenEvent.call(:feed_update_handler, __MODULE__, :vehicles)
  end

  def handle_event({:update, vehicles}, state) do
    vehicles
    |> Enum.group_by(fn v -> v.route end)
    |> Enum.each(fn {rte, vs} ->
      broadcast("vehicles:routes", "update", %{route: rte, vehicles: vs})
    end)

    {:ok, vehicles}
  end

  def handle_call(:vehicles, state) do
    {:ok, state, state}
  end
end
