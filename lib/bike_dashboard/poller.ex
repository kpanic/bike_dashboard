defmodule BikeDashboard.Poller do
  @moduledoc """
  The Poller context.

  Polls the CityBikes API for station data every minute and broadcasts messages to the "stations" topic via Phoenix.PubSub.
  """

  @update_interval Application.compile_env(
                     :bike_dashboard,
                     :poller_update_interval,
                     :timer.seconds(30)
                   )
  @topic "stations"
  @url "https://api.citybik.es/v2/networks/nextbike-berlin"

  require Logger

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    {:ok, %{ref: nil, stations: [], randomize: false}, {:continue, :poll}}
  end

  def stations(randomize) do
    GenServer.call(__MODULE__, {:stations, Keyword.get(randomize, :randomize, false)})
  end

  def handle_continue(:poll, %{ref: ref, randomize: randomize} = state) do
    {ref, stations} = schedule_broadcast_stations(ref, randomize)
    {:noreply, %{state | ref: ref, stations: stations}}
  end

  def handle_info(:poll, %{ref: ref, randomize: randomize} = state) do
    {ref, stations} = schedule_broadcast_stations(ref, randomize)
    {:noreply, %{state | ref: ref, stations: stations}}
  end

  def handle_call({:stations, randomize}, _from, %{stations: stations} = state) do
    randomize = if randomize, do: true, else: state.randomize
    stations = if randomize, do: randomize_free_bikes(stations), else: stations
    {:reply, stations, %{state | stations: stations, randomize: randomize}}
  end

  def schedule_broadcast_stations(ref, randomize) do
    if ref, do: Process.cancel_timer(ref)
    stations = get_stations()

    stations = if randomize, do: randomize_free_bikes(stations), else: stations

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
        get_in(body, ["network", "stations"])

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
