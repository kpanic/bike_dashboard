defmodule BikeDashboardWeb.DashboardLive do
  use BikeDashboardWeb, :live_view

  require Logger
  @topic "stations"
  @chat_topic "chat:lobby"

  alias BikeDashboard.Poller
  alias BikeDashboardWeb.Presence

  def mount(_params, %{"user_name" => user_name, "user_id" => user_id} = _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(BikeDashboard.PubSub, @topic)
      Phoenix.PubSub.subscribe(BikeDashboard.PubSub, @chat_topic)

      Presence.track(
        self(),
        @chat_topic,
        user_id,
        %{joined_at: System.system_time(:second)}
      )
    end

    user = %{
      id: user_id,
      name: user_name
    }

    assigns =
      socket
      |> assign(stations: [], ref: nil, dark: true, user: user)
      |> assign(messages: BikeDashboard.ChatHistory.all_messages())
      |> assign(form: to_form(%{"message" => ""}))
      |> assign(chat_open: false)
      |> assign(online_user_ids: [])
      |> start_async(:stations, fn -> Poller.stations() end)

    {:ok, assigns}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto w-[80%]">
      <h1 class="font-bold">Online: {length(@online_user_ids)}</h1>
      <%= if @chat_open do %>
        <h1 class="font-bold">Bikers Chat</h1>

        <div class="mt-6 border rounded p-4 flex flex-col">
          <!-- messages list -->
          <div
            id="chat-messages"
            phx-hook="AutoScroll"
            class="overflow-y-auto max-h-20 mb-3 space-y-1"
          >
            <%= for msg <- @messages do %>
              <div class="text-sm">
                <%= if msg.id in @online_user_ids do %>
                  🟢
                <% else %>
                  ⚪️
                <% end %>
                {msg.at} <strong>{msg.user}:</strong> {msg.body}
              </div>
            <% end %>
          </div>
          <!-- input -->
          <.form id="chat" for={@form} phx-submit="send-message" phx-change="change">
            <.input
              field={@form[:message]}
              placeholder="Type a message…"
              autocomplete="off"
              class="w-full border rounded p-4"
              autofocus
            />
          </.form>
        </div>
      <% end %>
      <!-- map -->
      <div
        class="w-full h-[750px] p-0 m-0"
        id="map"
        phx-update="ignore"
        phx-hook="StationsMap"
      >
      </div>
    </div>
    """
  end

  def handle_async(:stations, {:ok, stations}, socket) do
    {:noreply, update_stations(stations, socket)}
  end

  def handle_event("send-message", %{"message" => body}, socket) do
    {_date, erl_time} = :calendar.local_time()

    msg = %{
      id: socket.assigns.user.id,
      user: socket.assigns.user.name,
      body: body,
      at: Time.from_erl!(erl_time)
    }

    BikeDashboard.ChatHistory.add_message(msg)

    Phoenix.PubSub.broadcast(
      BikeDashboard.PubSub,
      @chat_topic,
      {:chat_message, msg}
    )

    {:noreply, assign(socket, form: to_form(%{"message" => ""}))}
  end

  def handle_event("change", params, socket) do
    {:noreply, assign(socket, form: to_form(params))}
  end

  def handle_event("toggle_chat", _params, socket) do
    {:noreply, update(socket, :chat_open, &(!&1))}
  end

  def handle_info({:stations, stations}, socket) do
    {:noreply, update_stations(stations, socket)}
  end

  def handle_info({:chat_message, msg}, socket) do
    {:noreply, update(socket, :messages, fn msgs -> msgs ++ [msg] end)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    user_ids =
      @chat_topic
      |> Presence.list()
      |> Map.keys()

    {:noreply, assign(socket, online_user_ids: user_ids)}
  end

  defp update_stations(stations, socket) do
    push_event(
      socket,
      "update-stations",
      %{
        stations: stations
      },
      dispatch: :before
    )
  end
end
