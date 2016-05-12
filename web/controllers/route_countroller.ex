defmodule Norta.RouteController do
  use Norta.Web, :controller

  def show(conn, %{"route_id" => route_id}) do
    route = Norta.GTFS.Agent.get_route(route_id)
    json conn, Norta.GTFS.Route.to_geo(route)
  end
end
