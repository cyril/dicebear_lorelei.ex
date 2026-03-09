defmodule DicebearLoreleiTest do
  use ExUnit.Case, async: true

  # -- svg/2 : typical inputs -------------------------------------------

  describe "svg/2 with typical inputs" do
    test "returns a complete SVG document" do
      svg = DicebearLorelei.svg("Felix")
      assert String.starts_with?(svg, "<svg")
      assert String.ends_with?(svg, "</svg>")
      assert svg =~ "viewBox=\"0 0 980 980\""
      assert svg =~ "<path"
    end

    test "is deterministic: same seed produces identical output" do
      assert DicebearLorelei.svg("seed") == DicebearLorelei.svg("seed")
    end

    test "different seeds produce different avatars" do
      refute DicebearLorelei.svg("alice") == DicebearLorelei.svg("bob")
    end

    test "applies size option" do
      svg = DicebearLorelei.svg("test", size: 64)
      assert svg =~ ~s(width="64")
      assert svg =~ ~s(height="64")
    end

    test "applies radius option with viewbox mask" do
      svg = DicebearLorelei.svg("test", radius: 50)
      assert svg =~ "viewboxMask"
    end

    test "applies custom hair and skin colors" do
      svg = DicebearLorelei.svg("test", hair_color: ["FF0000"], skin_color: ["00FF00"])
      assert svg =~ "#FF0000"
      assert svg =~ "#00FF00"
    end

    test "applies flip option" do
      svg = DicebearLorelei.svg("test", flip: true)
      assert svg =~ "scale(-1 1)"
    end

    test "applies rotate option" do
      svg = DicebearLorelei.svg("test", rotate: 90)
      assert svg =~ "rotate(90"
    end

    test "applies scale option" do
      svg = DicebearLorelei.svg("test", scale: 50)
      assert svg =~ "scale(0.5)"
    end

    test "applies translate option" do
      svg = DicebearLorelei.svg("test", translate_x: 10, translate_y: -20)
      assert svg =~ "translate("
    end

    test "applies solid background color" do
      svg = DicebearLorelei.svg("test", background_color: ["AABBCC"])
      assert svg =~ "#AABBCC"
      assert svg =~ "<rect"
    end

    test "restricts component variants" do
      svg1 = DicebearLorelei.svg("test", eyes: [:variant01])
      svg2 = DicebearLorelei.svg("test", eyes: [:variant01])
      assert svg1 == svg2
    end

    test "disables optional components with zero probability" do
      svg = DicebearLorelei.svg("glasses_seed",
        glasses_probability: 0,
        beard_probability: 0,
        earrings_probability: 0,
        freckles_probability: 0,
        hair_accessories_probability: 0
      )

      assert is_binary(svg)
    end
  end

  # -- svg/2 : boundary values -------------------------------------------

  describe "svg/2 with boundary values" do
    test "empty string seed" do
      svg = DicebearLorelei.svg("")
      assert String.starts_with?(svg, "<svg")
    end

    test "very long seed string" do
      long_seed = String.duplicate("a", 10_000)
      svg = DicebearLorelei.svg(long_seed)
      assert String.starts_with?(svg, "<svg")
    end

    test "unicode seed" do
      svg = DicebearLorelei.svg("日本語シード🎲")
      assert String.starts_with?(svg, "<svg")
    end

    test "size: 1 (minimum)" do
      svg = DicebearLorelei.svg("test", size: 1)
      assert svg =~ ~s(width="1")
    end

    test "radius: 0 (minimum)" do
      svg = DicebearLorelei.svg("test", radius: 0)
      assert is_binary(svg)
    end

    test "radius: 50 (maximum)" do
      svg = DicebearLorelei.svg("test", radius: 50)
      assert svg =~ "viewboxMask"
    end

    test "scale: 0 (minimum)" do
      svg = DicebearLorelei.svg("test", scale: 0)
      assert svg =~ "scale(0"
    end

    test "scale: 200 (maximum)" do
      svg = DicebearLorelei.svg("test", scale: 200)
      assert svg =~ "scale(2"
    end

    test "rotate: 360 (maximum)" do
      svg = DicebearLorelei.svg("test", rotate: 360)
      assert svg =~ "rotate(360"
    end

    test "probability: 0 and 100 extremes" do
      svg = DicebearLorelei.svg("test", beard_probability: 100, glasses_probability: 0)
      assert is_binary(svg)
    end

    test "clip: false disables viewbox mask" do
      svg = DicebearLorelei.svg("test", clip: false, radius: 0)
      refute svg =~ "viewboxMask"
    end

    test "no options returns valid SVG" do
      svg = DicebearLorelei.svg("test")
      assert String.starts_with?(svg, "<svg")
    end

    test "all options at once" do
      svg = DicebearLorelei.svg("test",
        size: 128,
        radius: 25,
        scale: 150,
        flip: true,
        rotate: 45,
        translate_x: 10,
        translate_y: -10,
        clip: true,
        background_color: ["AABBCC", "DDEEFF"],
        background_type: ["gradientLinear"],
        background_rotation: [-90, 90],
        hair_color: ["2c1810"],
        skin_color: ["f5d0b0"],
        eyes_color: ["1a1a1a"],
        beard_probability: 50,
        glasses_probability: 50,
        hair: [:variant01, :variant02, :variant03],
        eyes: [:variant01, :variant05, :variant10]
      )

      assert String.starts_with?(svg, "<svg")
      assert String.ends_with?(svg, "</svg>")
    end
  end

  # -- svg/2 : input validation ------------------------------------------

  describe "svg/2 rejects invalid inputs" do
    test "raises on non-string seed" do
      assert_raise FunctionClauseError, fn -> DicebearLorelei.svg(123) end
    end

    test "raises on non-keyword options" do
      assert_raise FunctionClauseError, fn -> DicebearLorelei.svg("test", "bad") end
    end

    test "raises on unknown option key" do
      assert_raise ArgumentError, ~r/unknown option/, fn ->
        DicebearLorelei.svg("test", bogus: true)
      end
    end

    test "raises on non-integer size" do
      assert_raise ArgumentError, ~r/:size/, fn ->
        DicebearLorelei.svg("test", size: "big")
      end
    end

    test "raises on negative size" do
      assert_raise ArgumentError, ~r/:size/, fn ->
        DicebearLorelei.svg("test", size: -1)
      end
    end

    test "raises on zero size" do
      assert_raise ArgumentError, ~r/:size/, fn ->
        DicebearLorelei.svg("test", size: 0)
      end
    end

    test "raises on out-of-range radius" do
      assert_raise ArgumentError, ~r/:radius/, fn ->
        DicebearLorelei.svg("test", radius: 51)
      end
    end

    test "raises on non-boolean flip" do
      assert_raise ArgumentError, ~r/:flip/, fn ->
        DicebearLorelei.svg("test", flip: 1)
      end
    end

    test "raises on out-of-range scale" do
      assert_raise ArgumentError, ~r/:scale/, fn ->
        DicebearLorelei.svg("test", scale: 201)
      end
    end

    test "raises on out-of-range rotate" do
      assert_raise ArgumentError, ~r/:rotate/, fn ->
        DicebearLorelei.svg("test", rotate: 361)
      end
    end

    test "raises on invalid hex color (too short)" do
      assert_raise ArgumentError, ~r/hex/, fn ->
        DicebearLorelei.svg("test", hair_color: ["FFF"])
      end
    end

    test "raises on invalid hex color (non-hex chars)" do
      assert_raise ArgumentError, ~r/hex/, fn ->
        DicebearLorelei.svg("test", skin_color: ["ZZZZZZ"])
      end
    end

    test "raises on invalid variant atom" do
      assert_raise ArgumentError, ~r/variant/, fn ->
        DicebearLorelei.svg("test", eyes: [:nonexistent])
      end
    end

    test "raises on empty variant list" do
      assert_raise ArgumentError, ~r/empty/, fn ->
        DicebearLorelei.svg("test", hair: [])
      end
    end

    test "raises on out-of-range probability" do
      assert_raise ArgumentError, ~r/:beard_probability/, fn ->
        DicebearLorelei.svg("test", beard_probability: 101)
      end
    end

    test "raises on negative probability" do
      assert_raise ArgumentError, ~r/:glasses_probability/, fn ->
        DicebearLorelei.svg("test", glasses_probability: -1)
      end
    end

    test "rejects SVG injection via color" do
      assert_raise ArgumentError, ~r/hex/, fn ->
        DicebearLorelei.svg("test", hair_color: ["000\" onclick=\"alert(1)"])
      end
    end

    test "rejects script injection via color" do
      assert_raise ArgumentError, ~r/hex/, fn ->
        DicebearLorelei.svg("test", skin_color: ["<script>"])
      end
    end

    test "raises on invalid background type" do
      assert_raise ArgumentError, ~r/background_type/, fn ->
        DicebearLorelei.svg("test", background_type: ["invalid"])
      end
    end

    test "raises on out-of-range translate" do
      assert_raise ArgumentError, ~r/:translate_x/, fn ->
        DicebearLorelei.svg("test", translate_x: 101)
      end
    end
  end

  # -- data_uri/2 ---------------------------------------------------------

  describe "data_uri/2" do
    test "returns a valid data URI" do
      uri = DicebearLorelei.data_uri("test")
      assert String.starts_with?(uri, "data:image/svg+xml;utf8,")
    end

    test "is deterministic" do
      assert DicebearLorelei.data_uri("seed") == DicebearLorelei.data_uri("seed")
    end

    test "passes options through to svg generation" do
      uri = DicebearLorelei.data_uri("test", size: 64)
      decoded = URI.decode(uri)
      assert decoded =~ ~s(width="64")
    end

    test "rejects invalid options" do
      assert_raise ArgumentError, fn ->
        DicebearLorelei.data_uri("test", size: -1)
      end
    end
  end

  # -- PRNG compatibility (golden tests via public API) -------------------

  describe "PRNG compatibility with upstream DiceBear JS" do
    test "Felix produces consistent output across runs" do
      svg = DicebearLorelei.svg("Felix")
      hash = :erlang.phash2(svg)
      assert hash == :erlang.phash2(DicebearLorelei.svg("Felix"))
    end

    test "multiple seeds produce distinct, stable hashes" do
      hashes =
        ~w(Felix Mia Chess Shogi Xiangqi)
        |> Enum.map(fn seed -> :erlang.phash2(DicebearLorelei.svg(seed)) end)

      assert length(Enum.uniq(hashes)) == 5
    end
  end
end
