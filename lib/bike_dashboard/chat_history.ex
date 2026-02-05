defmodule BikeDashboard.ChatHistory do
  @table :chat_history

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    :ets.new(@table, [:named_table, :public, :ordered_set, read_concurrency: true])
    {:ok, %{}}
  end

  def table, do: @table

  def add_message(message) do
    :ets.insert(@table, {System.system_time(:millisecond), message})
  end

  def all_messages do
    :ets.tab2list(@table)
    |> Enum.sort_by(fn {ts, _msg} -> ts end)
    |> Enum.map(fn {_ts, msg} -> msg end)
  end

  def clear do
    :ets.delete_all_objects(@table)
  end
end
