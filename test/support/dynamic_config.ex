defmodule AbsintheAltair.TestDynamicConfig do
  @moduledoc false

  def headers, do: %{"X-Static" => "static-value"}

  def headers(conn), do: %{"X-Token" => conn.assigns[:token] || "none"}

  def endpoint, do: "/static/graphql"

  def endpoint(_conn), do: "/dynamic/graphql"
end
