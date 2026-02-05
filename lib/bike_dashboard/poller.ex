defmodule BikeDashboard.Poller do
  @moduledoc """
  The Poller context.

  Polls the CityBikes API for station data every minute and broadcasts messages to the "stations" topic via Phoenix.PubSub.
  """

  @update_interval Application.compile_env(
                     :bike_dashboard,
                     :poller_update_interval,
                     :timer.minutes(60)
                   )
  @topic "stations"
  @url "https://api.citybik.es/v2/networks/nextbike-berlin"

  require Logger

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    {:ok, %{ref: nil, stations: []}, {:continue, :poll}}
  end

  def stations() do
    GenServer.call(__MODULE__, :stations)
  end

  def handle_continue(:poll, %{ref: ref} = state) do
    {ref, stations} = schedule_broadcast_stations(ref)
    {:noreply, %{state | ref: ref, stations: stations}}
  end

  def handle_info(:poll, %{ref: ref} = state) do
    {ref, stations} = schedule_broadcast_stations(ref)
    {:noreply, %{state | ref: ref, stations: stations}}
  end

  def handle_call(:stations, _from, %{stations: stations} = state) do
    {:reply, stations, state}
  end

  def schedule_broadcast_stations(ref) do
    if ref, do: Process.cancel_timer(ref)
    stations = get_stations()

    Phoenix.PubSub.broadcast(
      BikeDashboard.PubSub,
      @topic,
      {:stations, stations}
    )

    Logger.info("Scheduling map update in #{@update_interval} ms")
    ref = Process.send_after(self(), :poll, @update_interval)
    {ref, stations}
  end

  defp get_stations() do
    case Req.get(@url) do
      {:ok, %{body: body}} ->
        body
        |> get_in(["network", "stations"])
        |> randomize_free_bikes()

      _ ->
        []
    end
  end

  defp randomize_free_bikes(stations) do
    Enum.map(stations, fn station ->
      Map.put(station, "free_bikes", Enum.random(0..1))
    end)
  end
end
