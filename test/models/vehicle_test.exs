defmodule Norta.VehicleTest do
  use Norta.ModelCase

  alias Norta.Vehicle

  @valid_attrs %{bearing: "120.5", car_type: "some content", gmt: "2010-04-17 14:00:00", lat: "120.5", lng: "120.5", name: 42, route: "some content", rt_name: "some content", speed: "120.5", train: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Vehicle.changeset(%Vehicle{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Vehicle.changeset(%Vehicle{}, @invalid_attrs)
    refute changeset.valid?
  end
end
