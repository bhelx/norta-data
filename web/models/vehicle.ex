defmodule Norta.Vehicle do
  use Norta.Web, :model
  require Logger
  alias Timex.Format.DateTime.Formatter

  schema "vehicles" do
    field :route, :string
    field :rt_name, :string
    field :name, :integer
    field :lat, :float
    field :lng, :float
    field :bearing, :float
    field :speed, :float
    field :car_type, :string
    field :train, :integer
    field :gmt, :string
    field :reading_time, Ecto.DateTime
    field :event_id, :integer
    field :stale, :boolean

    timestamps
  end

  @required_fields ~w(route rt_name name lat lng bearing speed car_type train event_id stale)
  @optional_fields ~w(reading_time gmt)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def from_map(map) do
    map = Map.update(map, :reading_time, nil, fn dt ->
      {:ok, dt} = Ecto.DateTime.cast(dt)
      Ecto.DateTime.to_erl(dt)
    end)

    Norta.Vehicle.changeset(%Norta.Vehicle{}, map)
  end
end
