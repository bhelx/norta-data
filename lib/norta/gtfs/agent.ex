defmodule Norta.GTFS.Agent do
  require Logger

  def start_link do
    Agent.start_link(fn -> load_gtfs end, name: __MODULE__)
  end

  def get_route(route_name) do
    Agent.get(__MODULE__, fn gtfs ->
      route_id = Map.get(gtfs[:route_short_names], route_name)
      Map.get(gtfs[:routes], route_id)
    end)
  end

  def get_routes do
    Agent.get(__MODULE__, fn gtfs ->
      gtfs[:routes]
      |> Map.values
      |> Enum.map(fn r ->
        Map.drop(r, [:shapes])
      end)
    end)
  end

  defp load_gtfs do
    Logger.info "Loading GTFS Data..."
    gtfs = Norta.GTFS.Parser.parse
    Logger.info "GTFS Data Loaded!"
    gtfs
  end
end
