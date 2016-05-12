defmodule Norta.PageController do
  use Norta.Web, :controller

  def index(conn, params) do
    render conn, "index.html", params: params
  end
end
