defmodule Norta.Feed.Parser do
  alias Norta.Feed.XmlNode
  alias Norta.Feed.Vehicle

  def parse_vehicles(xml_string) do
    doc = Norta.Feed.XmlNode.from_string(xml_string)

    doc
    |> XmlNode.all("//unit")
    |> Enum.map(&parse_vehicle(&1))
  end

  def parse_vehicle(xml_node) do
    attributes = ~w(route rt_name name lat lng bearing car_type speed GMT train)
      |> Enum.reduce([], fn(attr, attrs) -> [parse_vehicle_attribute(attr, xml_node) | attrs] end)
      |> Enum.into(%{})

    attributes |> Vehicle.from_map |> Vehicle.convert_coords |> Vehicle.convert_time
  end

  defp parse_vehicle_attribute(attribute, xml_node) do
    val = xml_node |> XmlNode.first("//#{attribute}") |> XmlNode.text

    {normalize_key(attribute), normalize_value(val)}
  end

  defp normalize_key(key) do
    key |> String.downcase |> String.to_atom
  end

  defp normalize_value(val) when is_binary(val) do
    Regex.replace(~r/\'/, val, "")
  end
  defp normalize_value(val) do
    val
  end
end
