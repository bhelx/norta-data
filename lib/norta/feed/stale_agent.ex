defmodule Norta.Feed.StaleAgent do
  require Logger

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, &(&1))
  end

  def merge(stales) do
    Agent.get_and_update(__MODULE__, fn state ->
      state = Map.merge(state, stales)
      {state, state}
    end)
  end
end
