defmodule BikeDashboardWeb.Presence do
  use Phoenix.Presence,
    otp_app: :bike_dashboard,
    pubsub_server: BikeDashboard.PubSub
end
