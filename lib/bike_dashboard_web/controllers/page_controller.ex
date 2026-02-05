defmodule BikeDashboardWeb.PageController do
  use BikeDashboardWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
