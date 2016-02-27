defmodule Exbackoff.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project do
    [app: :exbackoff,
     version: @version,
     elixir: "~> 1.2",
     description: description,
     package: package,
     source_url: "https://github.com/mingchuno/exbackoff",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"], main: "readme",
              source_ref: "v#{@version}",
              source_url: "https://github.com/mingchuno/exbackoff"]
    ]
  end

  defp description do
    """
    Simple exponential backoffs in Elixir.
    """
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:excheck, "~> 0.3.2", only: :test},
      {:earmark, "~> 0.1", only: :docs},
      {:ex_doc, "~> 0.10", only: :docs},
      {:inch_ex, "~> 0.4", only: :docs},
      {:triq, github: "krestenkrab/triq", only: :test}
    ]
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["MC Or"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/mingchuno/exbackoff"}]
  end
end
