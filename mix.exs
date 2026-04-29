defmodule AbsintheAltair.MixProject do
  use Mix.Project

  @version "2026.4.1"
  @source_url "https://github.com/paradox460/absinthe_altair"

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
      {:absinthe_plug, "~> 1.5", optional: true},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", runtime: false, only: [:dev, :test]},
      {:dialyxir, "~> 1.4", runtime: false, only: [:dev, :test]},
      {:quokka, "~> 2.12", runtime: false, only: [:dev, :test]}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
