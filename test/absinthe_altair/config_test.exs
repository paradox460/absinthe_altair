defmodule AbsintheAltair.ConfigTest do
  use ExUnit.Case, async: true

  alias AbsintheAltair.Config

  describe "resolve_value/2" do
    test "passes static strings through" do
      conn = Plug.Test.conn(:get, "/")
      assert Config.resolve_value("hello", conn) == "hello"
    end

    test "passes nil through" do
      conn = Plug.Test.conn(:get, "/")
      assert Config.resolve_value(nil, conn) == nil
    end

    test "passes maps through" do
      conn = Plug.Test.conn(:get, "/")
      assert Config.resolve_value(%{"key" => "val"}, conn) == %{"key" => "val"}
    end

    test "calls {mod, fun} arity-1 with conn" do
      conn = Plug.Test.conn(:get, "/") |> Plug.Conn.assign(:token, "abc123")

      result =
        Config.resolve_value({AbsintheAltair.TestDynamicConfig, :headers}, conn)

      assert result == %{"X-Token" => "abc123"}
    end

    test "prefers arity-1 when both arities exist" do
      conn = Plug.Test.conn(:get, "/")

      result =
        Config.resolve_value({AbsintheAltair.TestDynamicConfig, :endpoint}, conn)

      # arity-1 takes precedence over arity-0
      assert result == "/dynamic/graphql"
    end

    test "raises on non-exported function" do
      conn = Plug.Test.conn(:get, "/")

      assert_raise ArgumentError, ~r/not exported/, fn ->
        Config.resolve_value({AbsintheAltair.TestDynamicConfig, :nonexistent}, conn)
      end
    end
  end

  describe "to_js_key/1" do
    test "converts snake_case to camelCase" do
      assert Config.to_js_key(:initial_query) == "initialQuery"
      assert Config.to_js_key(:subscriptions_endpoint) == "subscriptionsEndpoint"
      assert Config.to_js_key(:initial_pre_request_script) == "initialPreRequestScript"
    end

    test "handles single-word keys" do
      assert Config.to_js_key(:theme) == "theme"
    end

    test "special-cases endpoint_url to endpointURL" do
      assert Config.to_js_key(:endpoint_url) == "endpointURL"
    end
  end

  describe "build_init_options/1" do
    test "produces empty object for empty config" do
      assert Config.build_init_options(%{}) == "{}"
    end

    test "includes endpoint_url as quoted string" do
      js = Config.build_init_options(%{endpoint_url: "/graphql"})
      assert js =~ "endpointURL: '/graphql'"
    end

    test "nil endpoint_url produces window.location expression" do
      js = Config.build_init_options(%{endpoint_url: nil})
      assert js =~ "endpointURL: window.location.origin + window.location.pathname"
    end

    test "omits keys with nil values (except endpoint_url)" do
      js = Config.build_init_options(%{subscriptions_endpoint: nil})
      refute js =~ "subscriptionsEndpoint"
    end

    test "omits empty string values" do
      js = Config.build_init_options(%{initial_query: ""})
      refute js =~ "initialQuery"
    end

    test "includes map values as JSON" do
      js = Config.build_init_options(%{initial_headers: %{"Auth" => "Bearer token"}})
      assert js =~ ~s("Auth":"Bearer token")
    end

    test "omits empty maps" do
      js = Config.build_init_options(%{initial_headers: %{}})
      refute js =~ "initialHeaders"
    end

    test "includes boolean values" do
      js = Config.build_init_options(%{preserve_state: true})
      assert js =~ "preserveState: true"

      js = Config.build_init_options(%{disable_account: false})
      assert js =~ "disableAccount: false"
    end

    test "includes numeric values" do
      js = Config.build_init_options(%{some_count: 42})
      assert js =~ "someCount: 42"
    end

    test "includes list values as JSON" do
      js = Config.build_init_options(%{initial_windows: [%{"query" => "{ hello }"}]})
      assert js =~ "initialWindows: "
    end

    test "omits empty lists" do
      js = Config.build_init_options(%{initial_windows: []})
      refute js =~ "initialWindows"
    end

    test "supports arbitrary keys" do
      js = Config.build_init_options(%{initial_name: "My API"})
      assert js =~ "initialName: 'My API'"
    end

    test "includes multiple options" do
      js =
        Config.build_init_options(%{
          endpoint_url: "/api",
          subscriptions_endpoint: "ws://localhost:4000/ws",
          initial_query: "{ hello }"
        })

      assert js =~ "endpointURL: '/api'"
      assert js =~ "subscriptionsEndpoint: 'ws://localhost:4000/ws'"
      assert js =~ "initialQuery: '{ hello }'"
    end
  end

  describe "js_escape/1" do
    test "escapes backslashes" do
      assert Config.js_escape("a\\b") == "a\\\\b"
    end

    test "escapes single quotes" do
      assert Config.js_escape("it's") == "it\\'s"
    end

    test "escapes newlines" do
      assert Config.js_escape("a\nb") == "a\\nb"
    end

    test "escapes carriage returns" do
      assert Config.js_escape("a\rb") == "a\\rb"
    end

    test "escapes closing script tags" do
      assert Config.js_escape("</script>") == "<\\/script>"
    end
  end
end
