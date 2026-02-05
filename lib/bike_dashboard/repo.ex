defmodule BikeDashboard.Repo do
  use Ecto.Repo,
    otp_app: :bike_dashboard,
    adapter: Ecto.Adapters.Postgres
end
