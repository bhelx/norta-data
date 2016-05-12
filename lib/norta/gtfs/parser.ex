defmodule Norta.GTFS.Parser do
  alias Norta.GTFS.Route
  alias Norta.GTFS.Shape
  alias Norta.GTFS.Route

  require Logger

  @route_headers ~w(route_id agency_id route_short_name route_long_name route_desc route_type route_url route_color route_text_color)
  @data_folder "data/RTA_GTFSDataFeed/20160417V.clean"

  def parse do
    load_csv_streams
    |> normalize_streams
    |> to_maps
    |> insert_shapes_into_routes
    |> to_structs
    |> insert_route_short_name_map
    |> Map.take([:routes, :route_short_names])
  end

  def normalize_streams(streams) do
    streams
    |> Enum.map(&normalize/1)
    |> Enum.into(%{})
  end

  def normalize({:routes, stream}) do
    normalized =
      stream
      |> Enum.map(fn route_map ->
        route_map
        |> Map.put("route_id", Regex.replace(~r/[^0-9]/, route_map["route_id"], ""))
        |> Map.put("route_short_name", Regex.replace(~r/[^0-9]/, Map.get(route_map, "route_short_name", ""), ""))
        |> Map.put("route_color", "#" <> Map.get(route_map, "route_color", ""))
      end)

    {:routes, normalized}
  end
  def normalize({key, stream}) do
    {key, stream}
  end

  def to_maps(streams) do
    keys = Map.keys(streams)
    streams = Enum.reduce(keys, streams, &to_map/2)
  end

  def to_map(:routes, streams) do
    routes =
      streams[:routes]
      |> Enum.reduce(%{}, fn(r, acc) -> Map.put(acc, r["route_id"], r) end)

    Map.put(streams, :routes, routes)
  end
  def to_map(:trips, streams) do
    trips =
      streams[:trips]
      |> Enum.reduce(%{}, fn(r, acc) -> Map.put(acc, r["trip_id"], r) end)

    Map.put(streams, :trips, trips)
  end
  def to_map(:shapes, streams) do
    shapes =
      streams[:shapes]
      |> Enum.reduce(%{}, fn(r, acc) ->
        Map.update(acc, r["shape_id"], [], &([r | &1]))
      end)

    Map.put(streams, :shapes, shapes)
  end
  def to_map(:stops, streams) do
    stops =
      streams[:stops]
      |> Enum.reduce(%{}, fn(r, acc) -> Map.put(acc, r["stop_id"], r) end)

    Map.put(streams, :stops, stops)
  end

  def insert_shapes_into_routes(streams) do
    routes =
      streams[:routes]
      |> Enum.map(fn {route_id, route} ->
        shapes =
          streams[:trips]
          |> Enum.filter(fn {id, t} -> t["route_id"] == route_id end)
          |> Enum.map(fn {id, t} -> t["shape_id"] end)
          |> Enum.uniq
          |> Enum.map(fn shape_id -> streams[:shapes][shape_id] end)
          |> List.flatten

        route = Map.put(route, "shapes", shapes)

        {route_id, route}
      end)
      |> Enum.into(%{})

    Map.put(streams, :routes, routes)
  end

  def to_structs(streams) do
    routes =
      streams[:routes]
      |> Enum.map(fn {id, r} -> {id, Route.from_map(r)} end)
      |> Enum.map(fn {id, r} ->
        route = Map.update(r, :shapes, [], fn s ->
          Enum.map(s, &Shape.from_map/1)
        end)
        {id, route}
      end)
      |> Enum.into(%{})

    Map.put(streams, :routes, routes)
  end

  def insert_route_short_name_map(streams) do
    short_name_map =
      streams[:routes]
      |> Enum.reduce(%{}, fn({id, r}, acc) ->
        Map.put(acc, r.route_short_name, r.route_id)
      end)

    Map.put(streams, :route_short_names, short_name_map)
  end

  def load_csv_streams do
    files = ~w(routes trips stops shapes)a

    Enum.reduce(files, %{}, fn(file, state) ->
      Map.put(state, file, csv_stream(file))
    end)
  end

  def csv_stream(file) do
    File.stream!("#{@data_folder}/#{file}.txt")
    |> CSV.decode(headers: true)
  end

end
