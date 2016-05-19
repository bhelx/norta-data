defmodule Norta.PageView do
  use Norta.Web, :view

  def js_encode(params) do
    Poison.encode!(params)
  end

  def routes do
    Norta.GtfsAgent.get_routes
  end
end
