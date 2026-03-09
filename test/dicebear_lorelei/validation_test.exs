defmodule DicebearLorelei.ValidationTest do
  use ExUnit.Case, async: true

  alias DicebearLorelei.Validation

  # ---------------------------------------------------------------------------
  # validate!/1 — return structure
  # ---------------------------------------------------------------------------

  describe "validate!/1 return structure" do
    test "returns a map with defaults merged" do
      result = Validation.validate!(seed: "Felix")
      assert is_map(result)
      assert result.seed == "Felix"
    end

    test "preserves default values for unspecified options" do
      defaults = DicebearLorelei.Options.defaults()
      result = Validation.validate!(seed: "Felix")

      assert result.flip == defaults.flip
      assert result.scale == defaults.scale
      assert result.radius == defaults.radius
      assert result.clip == defaults.clip
      assert result.beard_probability == defaults.beard_probability
    end

    test "overrides take precedence over defaults" do
      result = Validation.validate!(seed: "Felix", size: 128, flip: true, rotate: 45)
      assert result.size == 128
      assert result.flip == true
      assert result.rotate == 45
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — unknown keys
  # ---------------------------------------------------------------------------

  describe "validate!/1 unknown keys" do
    test "raises on unknown option key" do
      assert_raise ArgumentError, ~r/unknown option :bogus/, fn ->
        Validation.validate!(seed: "Felix", bogus: true)
      end
    end

    test "raises on multiple unknown keys (first encountered)" do
      assert_raise ArgumentError, ~r/unknown option/, fn ->
        Validation.validate!(seed: "Felix", foo: 1, bar: 2)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — :seed
  # ---------------------------------------------------------------------------

  describe "validate!/1 :seed" do
    test "accepts a string" do
      assert %{seed: "hello"} = Validation.validate!(seed: "hello")
    end

    test "accepts an empty string" do
      assert %{seed: ""} = Validation.validate!(seed: "")
    end

    test "rejects non-string values" do
      for value <- [123, nil, :atom, true, []] do
        assert_raise ArgumentError, ~r/invalid :seed/, fn ->
          Validation.validate!(seed: value)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — :flip
  # ---------------------------------------------------------------------------

  describe "validate!/1 :flip" do
    test "accepts true and false" do
      assert %{flip: true} = Validation.validate!(seed: "s", flip: true)
      assert %{flip: false} = Validation.validate!(seed: "s", flip: false)
    end

    test "rejects non-boolean values" do
      for value <- [0, 1, "true", nil, :yes] do
        assert_raise ArgumentError, ~r/invalid :flip/, fn ->
          Validation.validate!(seed: "s", flip: value)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — :clip
  # ---------------------------------------------------------------------------

  describe "validate!/1 :clip" do
    test "accepts true and false" do
      assert %{clip: true} = Validation.validate!(seed: "s", clip: true)
      assert %{clip: false} = Validation.validate!(seed: "s", clip: false)
    end

    test "rejects non-boolean values" do
      assert_raise ArgumentError, ~r/invalid :clip/, fn ->
        Validation.validate!(seed: "s", clip: "true")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — integer range options
  # ---------------------------------------------------------------------------

  describe "validate!/1 :rotate (0..360)" do
    test "accepts boundary values" do
      assert %{rotate: 0} = Validation.validate!(seed: "s", rotate: 0)
      assert %{rotate: 360} = Validation.validate!(seed: "s", rotate: 360)
      assert %{rotate: 180} = Validation.validate!(seed: "s", rotate: 180)
    end

    test "rejects out-of-range values" do
      assert_raise ArgumentError, ~r/invalid :rotate/, fn ->
        Validation.validate!(seed: "s", rotate: -1)
      end

      assert_raise ArgumentError, ~r/invalid :rotate/, fn ->
        Validation.validate!(seed: "s", rotate: 361)
      end
    end

    test "rejects non-integer values" do
      assert_raise ArgumentError, ~r/invalid :rotate/, fn ->
        Validation.validate!(seed: "s", rotate: 1.5)
      end
    end
  end

  describe "validate!/1 :scale (0..200)" do
    test "accepts boundary values" do
      assert %{scale: 0} = Validation.validate!(seed: "s", scale: 0)
      assert %{scale: 200} = Validation.validate!(seed: "s", scale: 200)
    end

    test "rejects out-of-range values" do
      assert_raise ArgumentError, ~r/invalid :scale/, fn ->
        Validation.validate!(seed: "s", scale: 201)
      end
    end
  end

  describe "validate!/1 :radius (0..50)" do
    test "accepts boundary values" do
      assert %{radius: 0} = Validation.validate!(seed: "s", radius: 0)
      assert %{radius: 50} = Validation.validate!(seed: "s", radius: 50)
    end

    test "rejects out-of-range values" do
      assert_raise ArgumentError, ~r/invalid :radius/, fn ->
        Validation.validate!(seed: "s", radius: 51)
      end
    end
  end

  describe "validate!/1 :translate_x (-100..100)" do
    test "accepts boundary values" do
      assert %{translate_x: -100} = Validation.validate!(seed: "s", translate_x: -100)
      assert %{translate_x: 100} = Validation.validate!(seed: "s", translate_x: 100)
      assert %{translate_x: 0} = Validation.validate!(seed: "s", translate_x: 0)
    end

    test "rejects out-of-range values" do
      assert_raise ArgumentError, ~r/invalid :translate_x/, fn ->
        Validation.validate!(seed: "s", translate_x: -101)
      end

      assert_raise ArgumentError, ~r/invalid :translate_x/, fn ->
        Validation.validate!(seed: "s", translate_x: 101)
      end
    end
  end

  describe "validate!/1 :translate_y (-100..100)" do
    test "accepts boundary values" do
      assert %{translate_y: -100} = Validation.validate!(seed: "s", translate_y: -100)
      assert %{translate_y: 100} = Validation.validate!(seed: "s", translate_y: 100)
    end

    test "rejects out-of-range values" do
      assert_raise ArgumentError, ~r/invalid :translate_y/, fn ->
        Validation.validate!(seed: "s", translate_y: 101)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — :size
  # ---------------------------------------------------------------------------

  describe "validate!/1 :size" do
    test "accepts nil" do
      assert %{size: nil} = Validation.validate!(seed: "s", size: nil)
    end

    test "accepts positive integers" do
      assert %{size: 1} = Validation.validate!(seed: "s", size: 1)
      assert %{size: 1024} = Validation.validate!(seed: "s", size: 1024)
    end

    test "rejects zero" do
      assert_raise ArgumentError, ~r/invalid :size/, fn ->
        Validation.validate!(seed: "s", size: 0)
      end
    end

    test "rejects negative integers" do
      assert_raise ArgumentError, ~r/invalid :size/, fn ->
        Validation.validate!(seed: "s", size: -1)
      end
    end

    test "rejects non-integer values" do
      for value <- [1.5, "128", :large] do
        assert_raise ArgumentError, ~r/invalid :size/, fn ->
          Validation.validate!(seed: "s", size: value)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — probability options (0..100)
  # ---------------------------------------------------------------------------

  @probability_keys [
    :beard_probability,
    :earrings_probability,
    :freckles_probability,
    :glasses_probability,
    :hair_accessories_probability
  ]

  describe "validate!/1 probability options" do
    for key <- @probability_keys do
      test "#{key} accepts 0, 50, and 100" do
        key = unquote(key)

        for val <- [0, 50, 100] do
          result = Validation.validate!([{:seed, "s"}, {key, val}])
          assert Map.get(result, key) == val
        end
      end

      test "#{key} rejects out-of-range values" do
        key = unquote(key)

        assert_raise ArgumentError, ~r/invalid/, fn ->
          Validation.validate!([{:seed, "s"}, {key, -1}])
        end

        assert_raise ArgumentError, ~r/invalid/, fn ->
          Validation.validate!([{:seed, "s"}, {key, 101}])
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — variant list options
  # ---------------------------------------------------------------------------

  describe "validate!/1 variant list options" do
    test "accepts a valid variant list and converts to tuple" do
      result = Validation.validate!(seed: "s", eyes: [:variant01, :variant02])
      assert result.eyes == {:variant01, :variant02}
    end

    test "accepts a single-element variant list" do
      result = Validation.validate!(seed: "s", nose: [:variant01])
      assert result.nose == {:variant01}
    end

    test "rejects an empty list" do
      assert_raise ArgumentError, ~r/list must not be empty/, fn ->
        Validation.validate!(seed: "s", eyes: [])
      end
    end

    test "rejects an invalid variant atom" do
      assert_raise ArgumentError, ~r/invalid :eyes variant/, fn ->
        Validation.validate!(seed: "s", eyes: [:nonexistent])
      end
    end

    test "rejects non-list values" do
      assert_raise ArgumentError, ~r/expected a non-empty list/, fn ->
        Validation.validate!(seed: "s", eyes: :variant01)
      end
    end

    test "validates all component variant keys" do
      component_keys = [
        {:hair, :variant01},
        {:head, :variant01},
        {:eyes, :variant01},
        {:eyebrows, :variant01},
        {:mouth, :happy01},
        {:nose, :variant01},
        {:beard, :variant01},
        {:glasses, :variant01},
        {:earrings, :variant01},
        {:freckles, :variant01},
        {:hair_accessories, :flowers}
      ]

      for {key, valid_variant} <- component_keys do
        result = Validation.validate!([{:seed, "s"}, {key, [valid_variant]}])
        assert Map.get(result, key) == {valid_variant}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — color list options
  # ---------------------------------------------------------------------------

  describe "validate!/1 color list options" do
    test "accepts valid hex strings and converts to tuple" do
      result = Validation.validate!(seed: "s", hair_color: ["ff0000", "00ff00"])
      assert result.hair_color == {"ff0000", "00ff00"}
    end

    test "accepts uppercase hex strings" do
      result = Validation.validate!(seed: "s", hair_color: ["FF00AA"])
      assert result.hair_color == {"FF00AA"}
    end

    test "accepts mixed-case hex strings" do
      result = Validation.validate!(seed: "s", hair_color: ["aA1bB2"])
      assert result.hair_color == {"aA1bB2"}
    end

    test "accepts an empty color list" do
      result = Validation.validate!(seed: "s", hair_color: [])
      assert result.hair_color == {}
    end

    test "rejects hex strings with wrong length" do
      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: ["12345"])
      end

      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: ["1234567"])
      end
    end

    test "rejects hex strings with invalid characters" do
      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: ["GG0000"])
      end

      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: ["zzzzzz"])
      end
    end

    test "rejects empty string" do
      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: [""])
      end
    end

    test "rejects non-string elements" do
      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: [123_456])
      end
    end

    test "rejects non-list value" do
      assert_raise ArgumentError, ~r/expected a list of hex color strings/, fn ->
        Validation.validate!(seed: "s", hair_color: "ff0000")
      end
    end

    test "rejects hex strings with spaces" do
      assert_raise ArgumentError, ~r/expected a 6-character hex string/, fn ->
        Validation.validate!(seed: "s", hair_color: ["00 000"])
      end
    end

    test "validates all color option keys" do
      color_keys = [
        :hair_color,
        :skin_color,
        :eyes_color,
        :eyebrows_color,
        :mouth_color,
        :nose_color,
        :glasses_color,
        :earrings_color,
        :freckles_color,
        :hair_accessories_color,
        :background_color
      ]

      for key <- color_keys do
        result = Validation.validate!([{:seed, "s"}, {key, ["aabbcc"]}])
        assert Map.get(result, key) == {"aabbcc"}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — :background_type
  # ---------------------------------------------------------------------------

  describe "validate!/1 :background_type" do
    test "accepts valid types and converts to tuple" do
      result = Validation.validate!(seed: "s", background_type: ["solid"])
      assert result.background_type == {"solid"}
    end

    test "accepts both types together" do
      result = Validation.validate!(seed: "s", background_type: ["solid", "gradientLinear"])
      assert result.background_type == {"solid", "gradientLinear"}
    end

    test "rejects invalid type strings" do
      assert_raise ArgumentError, ~r/invalid :background_type element/, fn ->
        Validation.validate!(seed: "s", background_type: ["radial"])
      end
    end

    test "rejects non-list value" do
      assert_raise ArgumentError, ~r/expected a list of strings/, fn ->
        Validation.validate!(seed: "s", background_type: "solid")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # validate!/1 — :background_rotation
  # ---------------------------------------------------------------------------

  describe "validate!/1 :background_rotation" do
    test "accepts valid integers in range and converts to tuple" do
      result = Validation.validate!(seed: "s", background_rotation: [-90, 0, 90])
      assert result.background_rotation == {-90, 0, 90}
    end

    test "accepts boundary values" do
      result = Validation.validate!(seed: "s", background_rotation: [-360, 360])
      assert result.background_rotation == {-360, 360}
    end

    test "rejects out-of-range values" do
      assert_raise ArgumentError, ~r/invalid :background_rotation element/, fn ->
        Validation.validate!(seed: "s", background_rotation: [-361])
      end

      assert_raise ArgumentError, ~r/invalid :background_rotation element/, fn ->
        Validation.validate!(seed: "s", background_rotation: [361])
      end
    end

    test "rejects non-integer elements" do
      assert_raise ArgumentError, ~r/invalid :background_rotation element/, fn ->
        Validation.validate!(seed: "s", background_rotation: [1.5])
      end
    end

    test "rejects non-list value" do
      assert_raise ArgumentError, ~r/expected a list of integers/, fn ->
        Validation.validate!(seed: "s", background_rotation: 90)
      end
    end
  end
end
