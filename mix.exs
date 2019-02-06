defmodule Exbackoff.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/mingchuno/exbackoff"

  def project do
    [
      app: :exbackoff,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @repo_url,
      homepage_url: @repo_url
    ]
  end

  defp description do
    """
    Simple exponential backoffs in Elixir.
    """
  end

  defp package do
    [
      name: "exbackoff",
      # files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["MC Or"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excheck, "~> 0.6", only: :test},
      {:triq, "~> 1.3", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
