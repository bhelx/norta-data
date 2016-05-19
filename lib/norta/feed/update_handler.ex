defmodule Norta.Feed.UpdateHandler do
  use GenEvent, otp_app: :norta

  import Norta.Endpoint, only: [broadcast: 3]

  def vehicles do
    GenEvent.call(:feed_update_handler, __MODULE__, :vehicles)
  end

  def handle_event({:update, vehicles}, prev_vehicle_groups) do
    new_vehicle_groups = group_vehicles(vehicles)

    # all the routes new and old
    all_routes = uniq_routes(new_vehicle_groups, prev_vehicle_groups)

    Enum.each(all_routes, fn rte ->
      prev_vehicles = Map.get(prev_vehicle_groups, rte, [])
      new_vehicles = Map.get(new_vehicle_groups, rte, [])

      # only broadcast if the vehicles on the route changed
      if new_vehicles != prev_vehicles do
        broadcast_vehicles(rte, new_vehicles)
      end
    end)

    {:ok, new_vehicle_groups}
  end

  defp uniq_routes(vehicle_group_1, vehicle_group_2) do
    vehicle_group_1
    |> Map.keys
    |> Enum.concat(Map.keys(vehicle_group_2))
    |> Enum.uniq
  end

  defp group_vehicles(vehicles) do
    Enum.group_by(vehicles, fn v -> v.route end)
  end

  def broadcast_vehicles(route, vehicles) do
    broadcast("vehicles:routes", "update", %{route: route, vehicles: vehicles})
  end

  def handle_call(:vehicles, vehicle_groups) do
    {:ok, vehicle_groups, vehicle_groups}
  end
end
