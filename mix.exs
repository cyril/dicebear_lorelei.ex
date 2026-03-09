defmodule DicebearLorelei.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/cyril/dicebear_lorelei.ex"

  def project do
    [
      app: :dicebear_lorelei,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "DicebearLorelei",
      description: "Pure Elixir port of the DiceBear Lorelei avatar style",
      source_url: @source_url,
      package: package(),
      dialyzer: [plt_local_path: "priv/plts"]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end
end
