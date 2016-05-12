defmodule Norta.VehicleChannel do
  use Norta.Web, :channel
  require Logger
  alias Norta.Feed.UpdateHandler

  intercept ["update"]

  def join("vehicles:routes", payload, socket) do
    routes = payload["routes"]

    Process.flag(:trap_exit, true)
    send(self, {:after_join, routes})

    {:ok, assign(socket, :routes, routes)}
  end

  def handle_out("update", payload, socket) do
    if payload[:route] in socket.assigns[:routes] do
      push socket, "update", payload
    end

    {:noreply, socket}
  end

  def handle_info({:after_join, routes}, socket) do
    # TODO improve
    all_vehicles = UpdateHandler.vehicles
    Enum.each(routes, fn route ->
      vehicles = Enum.filter(all_vehicles, fn v -> v.route == route end)
      push socket, "update", %{vehicles: vehicles , route: route}
    end)
    {:noreply, socket}
  end
end
