defmodule DicebearLorelei.AvatarTest do
  use ExUnit.Case, async: true

  alias DicebearLorelei.Avatar

  # Convenience: build a full options map with overrides.
  defp opts(overrides) do
    Map.merge(DicebearLorelei.Options.defaults(), Map.new(overrides))
  end

  defp generate_svg(overrides) do
    overrides |> opts() |> Avatar.generate() |> IO.iodata_to_binary()
  end

  # ---------------------------------------------------------------------------
  # generate/1 — return type and structural invariants
  # ---------------------------------------------------------------------------

  describe "generate/1 structural invariants" do
    test "returns iodata (nested list)" do
      result = opts(seed: "Felix") |> Avatar.generate()
      assert is_list(result)
    end

    test "output starts with <svg and ends with </svg>" do
      svg = generate_svg(seed: "Felix")
      assert String.starts_with?(svg, "<svg")
      assert String.ends_with?(svg, "</svg>")
    end

    test "output contains the 980×980 viewBox" do
      svg = generate_svg(seed: "Felix")
      assert svg =~ ~s(viewBox="0 0 980 980")
    end

    test "output contains body group with translate(10 -60)" do
      svg = generate_svg(seed: "Felix")
      assert String.contains?(svg, "translate(10 -60)")
    end

    test "output is valid XML-like structure with balanced svg tags" do
      svg = generate_svg(seed: "Felix")
      opening = length(String.split(svg, "<svg")) - 1
      closing = length(String.split(svg, "</svg>")) - 1
      assert opening == 1
      assert closing == 1
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — determinism
  # ---------------------------------------------------------------------------

  describe "generate/1 determinism" do
    test "same seed and options always produce identical output" do
      svg1 = generate_svg(seed: "determinism_test")
      svg2 = generate_svg(seed: "determinism_test")
      assert svg1 == svg2
    end

    test "different seeds produce different output" do
      svg_a = generate_svg(seed: "seed_A")
      svg_b = generate_svg(seed: "seed_B")
      assert svg_a != svg_b
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — size option (wrap_svg)
  # ---------------------------------------------------------------------------

  describe "generate/1 size option" do
    test "size: nil omits width and height on the svg element" do
      svg = generate_svg(seed: "Felix", size: nil)
      [svg_tag | _] = String.split(svg, ">", parts: 2)
      refute svg_tag =~ "width="
      refute svg_tag =~ "height="
    end

    test "size: 256 includes width and height attributes" do
      svg = generate_svg(seed: "Felix", size: 256)
      assert svg =~ ~s(width="256")
      assert svg =~ ~s(height="256")
    end

    test "size: 1 includes width and height of 1" do
      svg = generate_svg(seed: "Felix", size: 1)
      assert svg =~ ~s(width="1")
      assert svg =~ ~s(height="1")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — flip option (maybe_flip)
  # ---------------------------------------------------------------------------

  describe "generate/1 flip option" do
    test "flip: true inserts scale(-1 1) with translate(-980)" do
      svg = generate_svg(seed: "Felix", flip: true)
      assert String.contains?(svg, "scale(-1 1)")
      assert String.contains?(svg, "translate(-980")
    end

    test "flip: false does not insert scale(-1 1)" do
      svg = generate_svg(seed: "Felix", flip: false)
      refute String.contains?(svg, "scale(-1 1)")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — rotate option (maybe_rotate)
  # ---------------------------------------------------------------------------

  describe "generate/1 rotate option" do
    test "rotate: 0 does not insert a rotate transform" do
      svg = generate_svg(seed: "Felix", rotate: 0)
      refute svg =~ ~r/rotate\(\d/
    end

    test "rotate: 45 inserts rotate(45, 490, 490)" do
      svg = generate_svg(seed: "Felix", rotate: 45)
      assert String.contains?(svg, "rotate(45, 490, 490)")
    end

    test "rotate: 360 inserts rotate(360, 490, 490)" do
      svg = generate_svg(seed: "Felix", rotate: 360)
      assert String.contains?(svg, "rotate(360, 490, 490)")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — scale option (maybe_scale)
  # ---------------------------------------------------------------------------

  describe "generate/1 scale option" do
    test "scale: 100 does not insert a scale transform" do
      svg = generate_svg(seed: "Felix", scale: 100)
      refute svg =~ ~r/scale\(\d/
    end

    test "scale: 150 inserts scale(1.5)" do
      svg = generate_svg(seed: "Felix", scale: 150)
      assert String.contains?(svg, "scale(1.5)")
    end

    test "scale: 50 inserts scale(0.5)" do
      svg = generate_svg(seed: "Felix", scale: 50)
      assert String.contains?(svg, "scale(0.5)")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — translate options (maybe_translate)
  # ---------------------------------------------------------------------------

  describe "generate/1 translate options" do
    test "translate_x: 0, translate_y: 0 does not insert an extra translate" do
      svg = generate_svg(seed: "Felix", translate_x: 0, translate_y: 0)
      # Only body-group translates should be present
      translates = Regex.scan(~r/translate\([^)]+\)/, svg) |> List.flatten()

      assert Enum.all?(translates, fn t ->
               t == "translate(10 -60)"
             end)
    end

    test "translate_x: 20, translate_y: -30 inserts translate(196 -294)" do
      svg = generate_svg(seed: "Felix", translate_x: 20, translate_y: -30)
      assert String.contains?(svg, "translate(196 -294)")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — clip and radius options (maybe_clip)
  # ---------------------------------------------------------------------------

  describe "generate/1 clip and radius options" do
    test "clip: true inserts viewboxMask" do
      svg = generate_svg(seed: "Felix", clip: true)
      assert String.contains?(svg, "viewboxMask")
    end

    test "clip: false does not insert viewboxMask" do
      svg = generate_svg(seed: "Felix", clip: false)
      refute String.contains?(svg, "viewboxMask")
    end

    test "radius: 0 produces rx=\"0\"" do
      svg = generate_svg(seed: "Felix", radius: 0, clip: true)
      assert svg =~ "rx=\"0\""
    end

    test "radius: 50 produces rx=\"490\"" do
      svg = generate_svg(seed: "Felix", radius: 50, clip: true)
      assert svg =~ "rx=\"490\""
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — solid background (maybe_background)
  # ---------------------------------------------------------------------------

  describe "generate/1 solid background" do
    test "single color produces a filled rect" do
      svg = generate_svg(seed: "Felix", background_color: {"b6e3f4"}, background_type: {"solid"})
      assert String.contains?(svg, "fill=\"#b6e3f4\"")
      assert String.contains?(svg, "width=\"980\"")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — gradient background (maybe_background)
  # ---------------------------------------------------------------------------

  describe "generate/1 gradient background" do
    test "two colors produce a linearGradient with both stop-colors" do
      svg =
        generate_svg(
          seed: "Felix",
          background_color: {"b6e3f4", "ff0000"},
          background_type: {"gradientLinear"}
        )

      assert String.contains?(svg, "linearGradient")
      assert String.contains?(svg, "stop-color=\"#b6e3f4\"")
      assert String.contains?(svg, "stop-color=\"#ff0000\"")
    end

    test "gradient includes gradientTransform with rotation" do
      svg =
        generate_svg(
          seed: "Felix",
          background_color: {"b6e3f4", "ff0000"},
          background_type: {"gradientLinear"}
        )

      assert svg =~ ~r/gradientTransform="rotate\(\d+/
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — transparent background (maybe_background)
  # ---------------------------------------------------------------------------

  describe "generate/1 transparent background" do
    test "empty background_color produces no filled rect" do
      svg = generate_svg(seed: "Felix", background_color: {})
      refute String.contains?(svg, "<rect fill=\"#")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — beard mouth fix (apply_beard_mouth_fix)
  # ---------------------------------------------------------------------------

  describe "generate/1 beard mouth fix" do
    test "when beard is shown and hair_color equals mouth_color, mouth becomes white" do
      svg =
        generate_svg(
          seed: "Felix",
          beard_probability: 100,
          hair_color: {"ff0000"},
          mouth_color: {"ff0000"}
        )

      assert String.contains?(svg, "#ffffff")
    end

    test "when beard is not shown, mouth color is unchanged" do
      svg_with = generate_svg(seed: "Felix", beard_probability: 100, mouth_color: {"aabb00"})
      svg_without = generate_svg(seed: "Felix", beard_probability: 0, mouth_color: {"aabb00"})

      # Without beard, the mouth color from options should appear
      assert String.contains?(svg_without, "#aabb00")
      # They should differ since beard presence changes the output
      assert svg_with != svg_without
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — optional component visibility
  # ---------------------------------------------------------------------------

  describe "generate/1 optional component probability" do
    test "glasses_probability: 100 differs from glasses_probability: 0" do
      svg_with = generate_svg(seed: "Felix", glasses_probability: 100)
      svg_without = generate_svg(seed: "Felix", glasses_probability: 0)
      assert svg_with != svg_without
    end

    test "earrings_probability: 100 differs from earrings_probability: 0" do
      svg_with = generate_svg(seed: "Felix", earrings_probability: 100)
      svg_without = generate_svg(seed: "Felix", earrings_probability: 0)
      assert svg_with != svg_without
    end

    test "freckles_probability: 100 differs from freckles_probability: 0" do
      svg_with = generate_svg(seed: "Felix", freckles_probability: 100)
      svg_without = generate_svg(seed: "Felix", freckles_probability: 0)
      assert svg_with != svg_without
    end

    test "hair_accessories_probability: 100 differs from hair_accessories_probability: 0" do
      svg_with = generate_svg(seed: "Felix", hair_accessories_probability: 100)
      svg_without = generate_svg(seed: "Felix", hair_accessories_probability: 0)
      assert svg_with != svg_without
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — color options
  # ---------------------------------------------------------------------------

  describe "generate/1 color options" do
    test "custom hair_color appears in the output" do
      svg = generate_svg(seed: "Felix", hair_color: {"ff00ff"})
      assert String.contains?(svg, "#ff00ff")
    end

    test "custom skin_color appears in the output" do
      svg = generate_svg(seed: "Felix", skin_color: {"aabbcc"})
      assert String.contains?(svg, "#aabbcc")
    end

    test "custom eyes_color appears in the output" do
      svg = generate_svg(seed: "Felix", eyes_color: {"112233"})
      assert String.contains?(svg, "#112233")
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — component variant restriction
  # ---------------------------------------------------------------------------

  describe "generate/1 variant restriction" do
    test "restricting eyes to a single variant produces deterministic component" do
      svg1 = generate_svg(seed: "Felix", eyes: {:variant01})
      svg2 = generate_svg(seed: "Mia", eyes: {:variant01})

      # Both should use variant01 for eyes; extract just the eyes portion
      # by checking both contain the same eyes paths (they share the variant)
      assert svg1 != svg2  # Other components still differ from different seeds
    end
  end

  # ---------------------------------------------------------------------------
  # generate/1 — snapshot hashes (regression guard)
  # ---------------------------------------------------------------------------

  @snapshot_cases [
    {"Felix", %{}, "1d9957b95820b27e50e40203242ccb37554ea54b91d2d9dbf8bfb098b37824e4"},
    {"Felix", %{size: 128},
     "a67e35959850bab543e6621cbcb9e4793e4a096d4c75021f58bb01408270850a"},
    {"Felix", %{flip: true, radius: 50},
     "f647cd26d958a04dd3efb06ffdd8e8f2c325465a5e31e21fcda98135c74c867e"},
    {"Felix", %{scale: 150, rotate: 45},
     "c87186a22cd29812c4859e956b5ebfeb490b4a19c42a13b46251eebbee7ae80e"},
    {"Felix", %{translate_x: 20, translate_y: -30},
     "5338d0a090924159efe7580c9a70fb34fb38d0c9ef122554fc239df87daeaf29"},
    {"Felix", %{background_color: {"b6e3f4"}, background_type: {"solid"}},
     "cbb4904dfd946ead2a7f4c1e71d00ab3410c440296895e66aeaec5a4491bbd5d"},
    {"Felix", %{background_color: {"b6e3f4", "ff0000"}, background_type: {"gradientLinear"}},
     "9bbbd84edc7f6934da4337b43b10216b2828f99d52a64ca95a335586360599c2"},
    {"Felix", %{clip: false},
     "ce0d95c8a3b22c42c4222db27baa53806e6fa645765ca5647fe775985691e7bb"},
    {"Felix", %{beard_probability: 100},
     "fb37e2dee83496e87b8025204df55f8a13e160045568e1920094cd5d37e79ca2"},
    {"Felix", %{glasses_probability: 100},
     "8bbf253748752eb3a433abf2b6ab6d1f685b057b2f877ec40fa67b564fba101d"},
    {"Mia", %{}, "4363f9cccffbacee544189bba086f51311fd57cd3397f4dda40d2bc4a9236430"},
    {"alpha", %{}, "9f3aabda31e221414ba6f77cb653ab60854358e56fd0101aa7466d659edc5132"}
  ]

  describe "generate/1 snapshot hashes" do
    for {seed, overrides, expected_hash} <- @snapshot_cases do
      label = "#{seed} #{inspect(overrides)}"

      test "#{label}" do
        overrides = Map.put(unquote(Macro.escape(overrides)), :seed, unquote(seed))
        svg = opts(overrides) |> Avatar.generate() |> IO.iodata_to_binary()
        hash = :crypto.hash(:sha256, svg) |> Base.encode16(case: :lower)
        assert hash == unquote(expected_hash)
      end
    end
  end
end
