defmodule Norta.GTFS.Shape do
  @derive [Poison.Encoder]
  defstruct ~w(shape_id shape_dist_traveled shape_pt_lon shape_pt_lat shape_pt_sequence)a

  def from_map(attr_map) do
    atomized_map =
      attr_map
      |> Enum.map(fn {k, v} -> {String.to_atom(k), String.strip(v)} end)
      |> Enum.into(%{})

    struct(Norta.GTFS.Shape, atomized_map)
    |> Map.update(:shape_dist_traveled, 0.0, &parse_float/1)
    |> Map.update(:shape_pt_lat, 0.0, &parse_float/1)
    |> Map.update(:shape_pt_lon, 0.0, &parse_float/1)
    |> Map.update(:shape_pt_sequence, 0.0, &parse_int/1)
  end

  defp parse_float(val) do
    {f, _} = Float.parse(val)
    f
  end

  defp parse_int(val) do
    {f, _} = Integer.parse(val)
    f
  end
end
