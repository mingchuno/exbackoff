defmodule Exbackoff.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :exbackoff,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
