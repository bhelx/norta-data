defmodule Norta.GTFS.ShapePoint do
  defstruct ~w(lat lng dist sequence)a

  def from_map(attr_map) do
    atomized_map =
      attr_map
      |> Enum.map(fn {k, v} ->
        {String.to_atom(k), String.strip(v)}
      end)

    struct(Norta.GTFS.ShapePoint, atomized_map)
  end
end
