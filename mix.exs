defmodule AbsintheAltair.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/sandberg/absinthe_altair"

  def project do
    [
      app: :absinthe_altair,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A Plug for embedding the Altair GraphQL Client into Absinthe applications",
      package: package(),
      source_url: @source_url,
      docs: [
        main: "AbsintheAltair",
        source_ref: "v#{@version}",
        source_url: @source_url
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.14"},
      {:jason, "~> 1.0"},
      {:absinthe_plug, "~> 1.5", optional: true},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
