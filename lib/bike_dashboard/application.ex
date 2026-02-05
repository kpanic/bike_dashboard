defmodule BikeDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BikeDashboardWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bike_dashboard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BikeDashboard.PubSub},
      # Start a worker by calling: BikeDashboard.Worker.start_link(arg)
      BikeDashboard.Poller,
      BikeDashboard.ChatHistory,
      BikeDashboardWeb.Presence,
      # Start to serve requests, typically the last entry
      BikeDashboardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BikeDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BikeDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
