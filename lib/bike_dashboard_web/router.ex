defmodule BikeDashboardWeb.Router do
  use BikeDashboardWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {BikeDashboardWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_user_id_cookie)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", BikeDashboardWeb do
    pipe_through(:browser)

    live("/", DashboardLive)
  end

  defp put_user_id_cookie(conn, _opts) do
    unique_integer_string =
      [:positive]
      |> :erlang.unique_integer()
      |> Integer.to_string()

    case Plug.Conn.get_session(conn, :user_name) do
      nil ->
        conn
        |> Plug.Conn.put_session(:user_name, "#{Faker.Cat.name()}-#{unique_integer_string}")
        |> Plug.Conn.put_session(:user_id, unique_integer_string)

      _ ->
        conn
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", BikeDashboardWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bike_dashboard, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: BikeDashboardWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
