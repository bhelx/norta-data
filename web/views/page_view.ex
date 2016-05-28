defmodule Norta.PageView do
  use Norta.Web, :view

  def js_encode(params) do
    Poison.encode!(params)
  end

  def routes do
    Norta.GTFSAgent.get_routes
    |> Enum.sort(fn(r1, r2) -> r1.route_long_name < r2.route_long_name end)
  end
end
