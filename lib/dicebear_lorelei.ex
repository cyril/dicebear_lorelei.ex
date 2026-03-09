defmodule DicebearLorelei do
  @moduledoc """
  Pure Elixir port of the DiceBear Lorelei avatar style.

  Generates deterministic SVG avatars from a string seed. The design is by
  Lisa Wischofsky, licensed under CC0 1.0.

  ## Quick start

      svg = DicebearLorelei.svg("Felix")
      svg = DicebearLorelei.svg("Mia", size: 128, radius: 50)

  ## Options

    * `:size` — pixel size (positive integer or `nil`, default `nil`)
    * `:radius` — border radius percentage (integer 0–50, default 0)
    * `:scale` — scale percentage (integer 0–200, default 100)
    * `:flip` — mirror horizontally (boolean, default `false`)
    * `:rotate` — rotation degrees (integer 0–360, default 0)
    * `:clip` — clip to viewbox (boolean, default `true`)
    * `:translate_x` — horizontal shift percentage (integer -100–100, default 0)
    * `:translate_y` — vertical shift percentage (integer -100–100, default 0)
    * `:background_color` — list of hex color strings, e.g. `["b6e3f4"]`
    * `:background_type` — list of `"solid"` and/or `"gradientLinear"`
    * `:background_rotation` — list of angle integers for gradient rotation
    * `:hair_color`, `:skin_color`, `:eyes_color`, `:eyebrows_color`,
      `:mouth_color`, `:nose_color`, `:glasses_color`, `:earrings_color`,
      `:freckles_color`, `:hair_accessories_color` — lists of 6-char hex strings
    * `:hair`, `:head`, `:eyes`, `:eyebrows`, `:mouth`, `:nose`, `:beard`,
      `:glasses`, `:earrings`, `:freckles`, `:hair_accessories` — lists of
      variant atoms to restrict the PRNG selection pool
    * `:beard_probability`, `:earrings_probability`, `:freckles_probability`,
      `:glasses_probability`, `:hair_accessories_probability` — integer 0–100

  Colors must be 6-character hexadecimal strings without the `#` prefix.
  Invalid options raise `ArgumentError` with a descriptive message.

  ## Complexity

  Both `svg/2` and `data_uri/2` run in O(n) time where n is the length of
  the seed string. All other work is O(1) — the PRNG consumes a fixed number
  of steps per avatar and the SVG assembly concatenates a bounded number of
  pre-computed template fragments.
  """

  @doc """
  Generates an SVG avatar string for the given seed.

  Returns a valid SVG document as a UTF-8 string. Raises `ArgumentError`
  if any option is invalid.

  ## Examples

      iex> svg = DicebearLorelei.svg("Felix")
      iex> String.starts_with?(svg, "<svg")
      true

      iex> svg = DicebearLorelei.svg("Mia", size: 64)
      iex> svg =~ ~s(width="64")
      true
  """
  @spec svg(String.t(), keyword()) :: String.t()
  def svg(seed, opts \\ []) when is_binary(seed) and is_list(opts) do
    validated = DicebearLorelei.Validation.validate!(Keyword.put(opts, :seed, seed))

    validated
    |> DicebearLorelei.Avatar.generate()
    |> IO.iodata_to_binary()
  end

  @doc """
  Generates a data URI for embedding in HTML `<img>` tags.

  Raises `ArgumentError` if any option is invalid.

  ## Examples

      iex> uri = DicebearLorelei.data_uri("Felix")
      iex> String.starts_with?(uri, "data:image/svg+xml")
      true
  """
  @spec data_uri(String.t(), keyword()) :: String.t()
  def data_uri(seed, opts \\ []) when is_binary(seed) and is_list(opts) do
    svg_string = svg(seed, opts)
    "data:image/svg+xml;utf8," <> URI.encode(svg_string)
  end
end
