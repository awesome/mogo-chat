defmodule Room do
  use Ecto.Model
  use Mogo.ModelUtils

  queryable "rooms" do
    field :name, :string
    has_many :messages, Message
    has_many :room_user_states, RoomUserState
  end

  validate room,
    name: has_length(1..30)

  def public_attributes(record) do
    attributes(record, ["id", "name"])
  end

end
