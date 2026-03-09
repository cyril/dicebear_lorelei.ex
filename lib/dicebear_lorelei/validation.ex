defmodule DicebearLorelei.Validation do
  @moduledoc false

  # Valid variant atoms per component, as plain maps for O(1) lookup.
  # (MapSet stored in module attributes triggers dialyzer opaqueness warnings.)
  @valid_variants %{
    hair: Map.from_keys(DicebearLorelei.Components.Hair.variants(), true),
    head: Map.from_keys(DicebearLorelei.Components.Head.variants(), true),
    eyes: Map.from_keys(DicebearLorelei.Components.Eyes.variants(), true),
    eyebrows: Map.from_keys(DicebearLorelei.Components.Eyebrows.variants(), true),
    mouth: Map.from_keys(DicebearLorelei.Components.Mouth.variants(), true),
    nose: Map.from_keys(DicebearLorelei.Components.Nose.variants(), true),
    beard: Map.from_keys(DicebearLorelei.Components.Beard.variants(), true),
    glasses: Map.from_keys(DicebearLorelei.Components.Glasses.variants(), true),
    earrings: Map.from_keys(DicebearLorelei.Components.Earrings.variants(), true),
    freckles: Map.from_keys(DicebearLorelei.Components.Freckles.variants(), true),
    hair_accessories: Map.from_keys(DicebearLorelei.Components.HairAccessories.variants(), true)
  }

  @valid_background_types %{"solid" => true, "gradientLinear" => true}

  @known_keys Map.from_keys([
    :seed, :flip, :rotate, :scale, :radius, :size,
    :background_color, :background_type, :background_rotation,
    :translate_x, :translate_y, :clip,
    :beard, :beard_probability,
    :earrings, :earrings_color, :earrings_probability,
    :eyebrows, :eyebrows_color,
    :eyes, :eyes_color,
    :freckles, :freckles_color, :freckles_probability,
    :glasses, :glasses_color, :glasses_probability,
    :hair, :hair_accessories, :hair_accessories_color, :hair_accessories_probability,
    :hair_color, :head,
    :mouth, :mouth_color,
    :nose, :nose_color,
    :skin_color
  ], true)

  @doc false
  @spec validate!(keyword()) :: map()
  def validate!(opts) when is_list(opts) do
    reject_unknown_keys!(opts)

    defaults = DicebearLorelei.Options.defaults()

    Enum.reduce(opts, defaults, fn {key, value}, acc ->
      validated = validate_option!(key, value)
      Map.put(acc, key, validated)
    end)
  end

  # -- reject unknown keys ------------------------------------------------

  defp reject_unknown_keys!(opts) do
    Enum.each(opts, fn {key, _value} ->
      unless is_map_key(@known_keys, key) do
        raise ArgumentError,
              "unknown option #{inspect(key)}, valid options: #{inspect(Map.keys(@known_keys))}"
      end
    end)
  end

  # -- per-option validation ----------------------------------------------

  defp validate_option!(:seed, value) when is_binary(value), do: value

  defp validate_option!(:seed, value) do
    raise ArgumentError, "invalid :seed, expected a string, got: #{inspect(value)}"
  end

  defp validate_option!(:flip, value) when is_boolean(value), do: value

  defp validate_option!(:flip, value) do
    raise ArgumentError, "invalid :flip, expected a boolean, got: #{inspect(value)}"
  end

  defp validate_option!(:clip, value) when is_boolean(value), do: value

  defp validate_option!(:clip, value) do
    raise ArgumentError, "invalid :clip, expected a boolean, got: #{inspect(value)}"
  end

  defp validate_option!(:rotate, value), do: validate_integer!(:rotate, value, 0, 360)
  defp validate_option!(:scale, value), do: validate_integer!(:scale, value, 0, 200)
  defp validate_option!(:radius, value), do: validate_integer!(:radius, value, 0, 50)
  defp validate_option!(:translate_x, value), do: validate_integer!(:translate_x, value, -100, 100)
  defp validate_option!(:translate_y, value), do: validate_integer!(:translate_y, value, -100, 100)

  defp validate_option!(:size, nil), do: nil

  defp validate_option!(:size, value) when is_integer(value) and value >= 1, do: value

  defp validate_option!(:size, value) do
    raise ArgumentError, "invalid :size, expected nil or a positive integer, got: #{inspect(value)}"
  end

  # Probability options (0–100)
  defp validate_option!(key, value)
       when key in [
              :beard_probability,
              :earrings_probability,
              :freckles_probability,
              :glasses_probability,
              :hair_accessories_probability
            ] do
    validate_integer!(key, value, 0, 100)
  end

  # Variant list options → validated and converted to tuple
  defp validate_option!(key, value)
       when key in [
              :hair,
              :head,
              :eyes,
              :eyebrows,
              :mouth,
              :nose,
              :beard,
              :glasses,
              :earrings,
              :freckles,
              :hair_accessories
            ] do
    validate_variant_list!(key, value)
  end

  # Color list options → validated hex strings, converted to tuple
  defp validate_option!(key, value)
       when key in [
              :hair_color,
              :skin_color,
              :eyes_color,
              :eyebrows_color,
              :mouth_color,
              :nose_color,
              :glasses_color,
              :earrings_color,
              :freckles_color,
              :hair_accessories_color
            ] do
    validate_color_list!(key, value)
  end

  defp validate_option!(:background_color, value), do: validate_color_list!(:background_color, value)

  defp validate_option!(:background_type, value) when is_list(value) do
    Enum.each(value, fn item ->
      unless is_map_key(@valid_background_types, item) do
        raise ArgumentError,
              "invalid :background_type element #{inspect(item)}, " <>
                "expected \"solid\" or \"gradientLinear\""
      end
    end)

    List.to_tuple(value)
  end

  defp validate_option!(:background_type, value) do
    raise ArgumentError,
          "invalid :background_type, expected a list of strings, got: #{inspect(value)}"
  end

  defp validate_option!(:background_rotation, value) when is_list(value) do
    Enum.each(value, fn item ->
      unless is_integer(item) and item >= -360 and item <= 360 do
        raise ArgumentError,
              "invalid :background_rotation element #{inspect(item)}, " <>
                "expected an integer in -360..360"
      end
    end)

    List.to_tuple(value)
  end

  defp validate_option!(:background_rotation, value) do
    raise ArgumentError,
          "invalid :background_rotation, expected a list of integers, got: #{inspect(value)}"
  end

  # -- shared validators --------------------------------------------------

  defp validate_integer!(_key, value, min, max)
       when is_integer(value) and value >= min and value <= max do
    value
  end

  defp validate_integer!(key, value, min, max) do
    raise ArgumentError,
          "invalid #{inspect(key)}, expected an integer in #{min}..#{max}, got: #{inspect(value)}"
  end

  defp validate_variant_list!(key, value) when is_list(value) do
    valid_set = Map.fetch!(@valid_variants, key)

    Enum.each(value, fn item ->
      unless is_map_key(valid_set, item) do
        raise ArgumentError,
              "invalid #{inspect(key)} variant #{inspect(item)}, " <>
                "valid variants: #{inspect(Map.keys(valid_set))}"
      end
    end)

    case value do
      [] ->
        raise ArgumentError, "invalid #{inspect(key)}, list must not be empty"

      _ ->
        List.to_tuple(value)
    end
  end

  defp validate_variant_list!(key, value) do
    raise ArgumentError,
          "invalid #{inspect(key)}, expected a non-empty list of variant atoms, got: #{inspect(value)}"
  end

  defp validate_color_list!(key, value) when is_list(value) do
    Enum.each(value, fn item ->
      unless hex6?(item) do
        raise ArgumentError,
              "invalid #{inspect(key)} color #{inspect(item)}, " <>
                "expected a 6-character hex string (e.g. \"FF00AA\")"
      end
    end)

    List.to_tuple(value)
  end

  defp validate_color_list!(key, value) do
    raise ArgumentError,
          "invalid #{inspect(key)}, expected a list of hex color strings, got: #{inspect(value)}"
  end

  # -- hex validation (replaces Regex for zero-allocation checking) ----------

  defp hex6?(<<a, b, c, d, e, f>>) do
    hex_char?(a) and hex_char?(b) and hex_char?(c) and
      hex_char?(d) and hex_char?(e) and hex_char?(f)
  end

  defp hex6?(_), do: false

  defp hex_char?(c)
       when (c >= ?0 and c <= ?9) or (c >= ?a and c <= ?f) or (c >= ?A and c <= ?F),
       do: true

  defp hex_char?(_), do: false
end
