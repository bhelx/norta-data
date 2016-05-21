defmodule Norta.VehicleChannel do
  use Norta.Web, :channel
  require Logger
  alias Norta.Feed.ChannelBroadcastHandler

  intercept ["update"]

  def join("vehicles:routes", %{"routes" => routes}, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:after_join, routes})

    {:ok, assign(socket, :routes, routes)}
  end

  def handle_in("vehicles:subscribe", %{"routes" => routes}, socket) do
    Process.flag(:trap_exit, true)
    send(self, {:after_join, routes})

    {:noreply, assign(socket, :routes, routes)}
  end

  def handle_out("update", payload, socket) do
    if payload[:route] in socket.assigns[:routes] do
      push socket, "update", payload
    end

    {:noreply, socket}
  end

  def handle_info({:after_join, routes}, socket) do
    # TODO improve
    all_vehicles = ChannelBroadcastHandler.vehicles
    Enum.each(routes, fn route ->
      vehicles = Map.get(all_vehicles, route, [])
      push socket, "update", %{vehicles: vehicles, route: route}
    end)
    {:noreply, socket}
  end
end
