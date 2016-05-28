defmodule Norta.GTFSAgent do
  require Logger

  @gtfs_data_folder "data/RTA_GTFSDataFeed/20160417V.clean"

  def start_link do
    Agent.start_link(fn -> load_gtfs end, name: __MODULE__)
  end

  def get_route(route_name) do
    Agent.get(__MODULE__, fn gtfs ->
      route_id = gtfs.route_short_names[route_name]
      gtfs.routes[route_id]
    end)
  end

  def get_routes do
    Agent.get(__MODULE__, fn gtfs ->
      gtfs.routes
      |> Map.values
      |> Enum.map(fn r ->
        # We clear out the trips, don't need them
        Map.drop(r, [:trips])
      end)
    end)
  end

  defp load_gtfs do
    Logger.info "Loading GTFS Data..."
    gtfs_data = GTFS.parse(@gtfs_data_folder)
    Logger.info "GTFS Data Loaded!"
    gtfs_data
  end
end
