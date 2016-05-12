defmodule Norta.GTFS.Route do
  @derive [Poison.Encoder]
  defstruct ~w(agency_id route_color route_desc route_id route_long_name route_short_name route_text_color route_type route_url shapes)a

  def from_map(attr_map) do
    atomized_map =
      attr_map
      |> Enum.map(fn {k, v} ->
        if is_binary(v) do
          {String.to_atom(k), String.strip(v)}
        else
          {String.to_atom(k), v}
        end
      end)

    struct(Norta.GTFS.Route, atomized_map)
  end

  def to_geo(route) do
    coords =
      route.shapes
      |> Enum.map(fn shape -> [shape.shape_pt_lon, shape.shape_pt_lat] end)

    style = %{color: route.route_color}

    %{
      type: "LineString",
      coordinates: coords,
      properties: %{style: style}
    }
  end
end
