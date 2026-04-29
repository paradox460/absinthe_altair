defmodule AbsintheAltairTest do
  use ExUnit.Case, async: true

  defp html_conn(path \\ "/") do
    Plug.Test.conn(:get, path)
    |> Plug.Conn.put_req_header("accept", "text/html")
  end

  defp json_conn(path \\ "/") do
    Plug.Test.conn(:get, path)
    |> Plug.Conn.put_req_header("accept", "application/json")
  end

  describe "HTML requests" do
    test "returns 200 with text/html content type" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql")
      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.status == 200
      assert {"content-type", content_type} = List.keyfind(conn.resp_headers, "content-type", 0)
      assert content_type =~ "text/html"
    end

    test "response contains Altair initialization" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql")
      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "AltairGraphQL.init("
      assert conn.resp_body =~ "endpointURL: '/graphql'"
    end

    test "response contains correct CDN base URL" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql")
      conn = AbsintheAltair.call(html_conn(), opts)

      expected_base = AbsintheAltair.Assets.cdn_base_url()
      assert conn.resp_body =~ ~s(base href="#{expected_base}")
    end

    test "custom altair_version changes CDN URL" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql", altair_version: "7.0.0")
      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "altair-static@7.0.0"
      refute conn.resp_body =~ "altair-static@#{AbsintheAltair.Assets.default_version()}"
    end

    test "nil endpoint_url produces window.location expression" do
      opts = AbsintheAltair.init([])
      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "window.location.origin + window.location.pathname"
    end

    test "subscriptions endpoint is included when configured" do
      opts =
        AbsintheAltair.init(
          endpoint_url: "/graphql",
          subscriptions_endpoint: "ws://localhost:4000/ws"
        )

      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "subscriptionsEndpoint: 'ws://localhost:4000/ws'"
    end

    test "subscriptions protocol is included when configured" do
      opts =
        AbsintheAltair.init(
          endpoint_url: "/graphql",
          subscriptions_protocol: "graphql-ws"
        )

      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "subscriptionsProtocol: 'graphql-ws'"
    end

    test "initial query is included and escaped" do
      query = "{ user(id: 1) {\n  name\n} }"

      opts = AbsintheAltair.init(endpoint_url: "/graphql", initial_query: query)
      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "initialQuery:"
      assert conn.resp_body =~ "{ user(id: 1)"
    end

    test "initial headers map is JSON-encoded" do
      opts =
        AbsintheAltair.init(
          endpoint_url: "/graphql",
          initial_headers: %{"Authorization" => "Bearer tok"}
        )

      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "initialHeaders:"
      assert conn.resp_body =~ "Bearer tok"
    end

    test "dynamic {M,F} headers resolve with conn" do
      opts =
        AbsintheAltair.init(
          endpoint_url: "/graphql",
          initial_headers: {AbsintheAltair.TestDynamicConfig, :headers}
        )

      conn =
        html_conn()
        |> Plug.Conn.assign(:token, "secret123")
        |> AbsintheAltair.call(opts)

      assert conn.resp_body =~ "secret123"
    end

    test "dynamic {M,F} endpoint_url resolves" do
      opts =
        AbsintheAltair.init(endpoint_url: {AbsintheAltair.TestDynamicConfig, :endpoint})

      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ "endpointURL: '/dynamic/graphql'"
    end

    test "response loads Altair JS assets" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql")
      conn = AbsintheAltair.call(html_conn(), opts)

      assert conn.resp_body =~ ~s(src="main.js")
      assert conn.resp_body =~ ~s(src="polyfills.js")
      assert conn.resp_body =~ ~s(href="styles.css")
    end
  end

  describe "non-HTML requests" do
    test "returns 406 when no schema configured" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql")
      conn = AbsintheAltair.call(json_conn(), opts)

      assert conn.status == 406
    end

    test "returns 406 when no accept header present" do
      opts = AbsintheAltair.init(endpoint_url: "/graphql")
      conn = Plug.Test.conn(:get, "/") |> AbsintheAltair.call(opts)

      assert conn.status == 406
    end
  end
end
