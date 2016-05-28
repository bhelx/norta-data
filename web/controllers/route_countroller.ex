defmodule Norta.RouteController do
  use Norta.Web, :controller

  def show(conn, %{"route_id" => route_id}) do
    route = Norta.GTFSAgent.get_route(route_id)
    json conn, route_to_geo(route)
  end

  # TODO this is not a good place for this logic
  defp route_to_geo(route) do
    style = %{color: route.route_color}

    coords =
      route.shapes
      |> Enum.map(fn {_id, shapes} ->
        Enum.map(shapes, fn shape ->
          [shape.shape_pt_lon, shape.shape_pt_lat]
        end)
      end)

    %{
      lines: coords,
      properties: %{style: style}
    }
  end
end
