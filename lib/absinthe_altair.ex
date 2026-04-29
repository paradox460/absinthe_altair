defmodule AbsintheAltair do
  @moduledoc """
  A Plug for embedding the [Altair GraphQL Client](https://altairgraphql.dev)
  into Phoenix and Absinthe applications.

  When a request arrives with `Accept: text/html`, the plug serves the Altair
  single-page application loaded from CDN. Otherwise, it optionally delegates
  to `Absinthe.Plug` for standard GraphQL API processing.

  ## Usage

      # In your Phoenix router
      forward "/altair", AbsintheAltair, endpoint_url: "/api/graphql"

  ## Options

  Any [Altair configuration property](https://altairgraphql.dev/api/core/config/classes/AltairConfig)
  can be passed as a snake_case atom option. Keys are automatically converted
  to camelCase for JavaScript (e.g. `:initial_query` becomes `initialQuery`).

  Common options:

    * `:endpoint_url` - The GraphQL endpoint URL. Accepts a string or
      `{module, function}` tuple. Defaults to `window.location` in the browser.

    * `:subscriptions_endpoint` - WebSocket URL for subscriptions. Accepts a
      string or `{module, function}` tuple.

    * `:subscriptions_protocol` - Subscription protocol. One of `"ws"`,
      `"graphql-ws"`, `"graphql-sse"`, `"app-sync"`, or `"action-cable"`.

    * `:initial_query` - Pre-populated GraphQL query string.

    * `:initial_variables` - Pre-populated variables string.

    * `:initial_headers` - Map of default headers, or `{module, function}` tuple.

    * `:initial_settings` - Map of Altair application settings.

  Plug-specific options:

    * `:altair_version` - The `altair-static` npm package version to load from
      CDN. Defaults to `"#{AbsintheAltair.Assets.default_version()}"`.

    * `:schema` - An Absinthe schema module. When set and `absinthe_plug` is
      available, non-HTML requests are delegated to `Absinthe.Plug`.

  Any `Absinthe.Plug` options (e.g. `:context`, `:pipeline`) are passed through
  to `Absinthe.Plug.init/1` when `:schema` is present and `absinthe_plug` is
  available.
  """

  @behaviour Plug

  require EEx

  @template_path Path.join(__DIR__, "absinthe_altair/templates")

  EEx.function_from_file(
    :defp,
    :altair_html,
    Path.join(@template_path, "altair.html.eex"),
    [:config]
  )

  @absinthe_plug_keys [
    :schema,
    :adapter,
    :context,
    :json_codec,
    :no_query_message,
    :pipeline,
    :document_providers,
    :log_level,
    :pubsub,
    :analyze_complexity,
    :max_complexity,
    :serializer,
    :transport_batch_payload_key,
    :before_send
  ]

  @impl Plug
  def init(opts) do
    {absinthe_opts, altair_opts} = Keyword.split(opts, @absinthe_plug_keys)

    config =
      altair_opts
      |> Map.new()
      |> Map.put_new(:altair_version, AbsintheAltair.Assets.default_version())
      |> Map.put_new(:endpoint_url, nil)

    if config[:schema] && absinthe_plug_available?() do
      absinthe_config = Absinthe.Plug.init(absinthe_opts)
      Map.put(config, :absinthe_plug_config, absinthe_config)
    else
      config
    end
  end

  @impl Plug
  def call(conn, config) do
    if html?(conn) do
      template_config = AbsintheAltair.Config.resolve_options(config, conn)

      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, altair_html(template_config))
    else
      case Map.get(config, :absinthe_plug_config) do
        nil ->
          conn
          |> Plug.Conn.put_resp_content_type("text/plain")
          |> Plug.Conn.send_resp(406, "Not Acceptable")

        absinthe_config ->
          Absinthe.Plug.call(conn, absinthe_config)
      end
    end
  end

  defp html?(conn) do
    case Plug.Conn.get_req_header(conn, "accept") do
      [accept | _] -> String.contains?(accept, "text/html")
      _ -> false
    end
  end

  defp absinthe_plug_available? do
    Code.ensure_loaded?(Absinthe.Plug)
  end
end
