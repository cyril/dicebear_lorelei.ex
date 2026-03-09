defmodule DicebearLorelei.Avatar do
  @moduledoc false

  alias DicebearLorelei.Prng

  alias DicebearLorelei.Components.{
    Hair,
    Head,
    Eyes,
    Eyebrows,
    Mouth,
    Nose,
    Beard,
    Glasses,
    Earrings,
    Freckles,
    HairAccessories
  }

  # -- constants (upstream Lorelei uses a fixed 980×980 canvas) -----------

  @canvas_size 980
  @canvas_origin 0
  @canvas_center div(@canvas_size, 2)
  @canvas_size_str Integer.to_string(@canvas_size)
  @canvas_origin_str Integer.to_string(@canvas_origin)
  @canvas_center_str Integer.to_string(@canvas_center)
  @neg_canvas_size_str Integer.to_string(-@canvas_size)
  @body_translate_x "10"
  @body_translate_y "-60"
  @beard_mouth_override "#ffffff"

  # -- public (called only by DicebearLorelei) ----------------------------

  @spec generate(map()) :: iodata()
  def generate(options) do
    prng = Prng.new(options.seed)

    {components, prng} = select_components(prng, options)
    {colors, prng} = select_colors(prng, options)
    colors = apply_beard_mouth_fix(components, colors)

    body = build_body(components, colors)
    {body, _prng} = apply_transforms(body, prng, options)

    wrap_svg(body, options)
  end

  # -- component selection (order matches getComponents.js exactly) -------

  defp select_components(prng, opts) do
    {hair, prng} = Prng.pick_tuple(prng, opts.hair)
    {hair_acc, prng} = Prng.pick_tuple(prng, opts.hair_accessories)
    {head, prng} = Prng.pick_tuple(prng, opts.head)
    {eyes, prng} = Prng.pick_tuple(prng, opts.eyes)
    {eyebrows, prng} = Prng.pick_tuple(prng, opts.eyebrows)
    {earrings_v, prng} = Prng.pick_tuple(prng, opts.earrings)
    {freckles_v, prng} = Prng.pick_tuple(prng, opts.freckles)
    {nose, prng} = Prng.pick_tuple(prng, opts.nose)
    {beard_v, prng} = Prng.pick_tuple(prng, opts.beard)
    {mouth, prng} = Prng.pick_tuple(prng, opts.mouth)
    {glasses_v, prng} = Prng.pick_tuple(prng, opts.glasses)

    {show_hair_acc?, prng} = Prng.bool(prng, opts.hair_accessories_probability)
    {show_earrings?, prng} = Prng.bool(prng, opts.earrings_probability)
    {show_freckles?, prng} = Prng.bool(prng, opts.freckles_probability)
    {show_beard?, prng} = Prng.bool(prng, opts.beard_probability)
    {show_glasses?, prng} = Prng.bool(prng, opts.glasses_probability)

    components = %{
      hair: {hair, Hair},
      hair_accessories: if(show_hair_acc?, do: {hair_acc, HairAccessories}),
      head: {head, Head},
      eyes: {eyes, Eyes},
      eyebrows: {eyebrows, Eyebrows},
      earrings: if(show_earrings?, do: {earrings_v, Earrings}),
      freckles: if(show_freckles?, do: {freckles_v, Freckles}),
      nose: {nose, Nose},
      beard: if(show_beard?, do: {beard_v, Beard}),
      mouth: {mouth, Mouth},
      glasses: if(show_glasses?, do: {glasses_v, Glasses})
    }

    {components, prng}
  end

  # -- color selection (order matches getColors.js exactly) ---------------

  defp select_colors(prng, opts) do
    {hair, prng} = pick_color(prng, opts.hair_color)
    {skin, prng} = pick_color(prng, opts.skin_color)
    {earrings, prng} = pick_color(prng, opts.earrings_color)
    {eyebrows, prng} = pick_color(prng, opts.eyebrows_color)
    {eyes, prng} = pick_color(prng, opts.eyes_color)
    {freckles, prng} = pick_color(prng, opts.freckles_color)
    {glasses, prng} = pick_color(prng, opts.glasses_color)
    {mouth, prng} = pick_color(prng, opts.mouth_color)
    {nose, prng} = pick_color(prng, opts.nose_color)
    {hair_acc, prng} = pick_color(prng, opts.hair_accessories_color)

    colors = %{
      hair: hair,
      skin: skin,
      earrings: earrings,
      eyebrows: eyebrows,
      eyes: eyes,
      freckles: freckles,
      glasses: glasses,
      mouth: mouth,
      nose: nose,
      hairAccessories: hair_acc
    }

    {colors, prng}
  end

  defp pick_color(prng, color_tuple) do
    {raw, prng} = Prng.pick_tuple(prng, color_tuple, :transparent)

    color =
      case raw do
        :transparent -> "transparent"
        hex when is_binary(hex) -> "#" <> hex
      end

    {color, prng}
  end

  # -- post-create hook (matches onPostCreate.js) -------------------------

  defp apply_beard_mouth_fix(components, colors) do
    if components.beard != nil and colors.hair == colors.mouth do
      %{colors | mouth: @beard_mouth_override}
    else
      colors
    end
  end

  # -- SVG body assembly (matches create() in index.js) -------------------

  defp build_body(components, colors) do
    [
      "<g transform=\"translate(",
      @body_translate_x,
      " ",
      @body_translate_y,
      ")\">",
      render_component(components, :hair, colors),
      "</g><g transform=\"translate(",
      @body_translate_x,
      " ",
      @body_translate_y,
      ")\">",
      render_component(components, :hair_accessories, colors),
      "</g>"
    ]
  end

  defp render_component(components, name, colors) do
    case Map.get(components, name) do
      {variant, module} -> module.svg(variant, components, colors)
      nil -> []
    end
  end

  # -- core transforms (order matches core.js pipeline) -------------------

  defp apply_transforms(body, prng, opts) do
    {background, prng} = resolve_background(prng, opts)

    body =
      body
      |> maybe_scale(opts.scale)
      |> maybe_flip(opts.flip)
      |> maybe_rotate(opts.rotate)
      |> maybe_translate(opts.translate_x, opts.translate_y)
      |> maybe_background(background)
      |> maybe_clip(opts.radius, opts.clip)

    {body, prng}
  end

  defp resolve_background(prng, opts) do
    {bg_type, prng} = Prng.pick_tuple(prng, opts.background_type, "solid")
    {bg_colors, prng} = pick_background_colors(prng, opts.background_color, bg_type)
    {bg_rotation, prng} = pick_background_rotation(prng, opts.background_rotation)
    {%{type: bg_type, colors: bg_colors, rotation: bg_rotation}, prng}
  end

  defp pick_background_rotation(prng, rotation) when tuple_size(rotation) == 0 do
    Prng.integer(prng, 0, 0)
  end

  defp pick_background_rotation(prng, rotation) do
    {min_val, max_val} = tuple_min_max(rotation)
    Prng.integer(prng, min_val, max_val)
  end

  defp tuple_min_max(tuple) do
    first = elem(tuple, 0)
    last = tuple_size(tuple) - 1

    Enum.reduce(1..last//1, {first, first}, fn i, {mn, mx} ->
      v = elem(tuple, i)
      {min(mn, v), max(mx, v)}
    end)
  end

  defp pick_background_colors(prng, colors, bg_type) do
    size = tuple_size(colors)

    {shuffled, prng} =
      cond do
        size <= 1 ->
          {_raw, prng} = Prng.next(prng)
          {colors, prng}

        size == 2 and bg_type == "gradientLinear" ->
          {_raw, prng} = Prng.next(prng)
          {colors, prng}

        true ->
          shuffle_tuple(prng, colors)
      end

    {primary, secondary} = background_pair(shuffled)
    {{primary, secondary}, prng}
  end

  defp background_pair(tuple) when tuple_size(tuple) == 0 do
    {"transparent", "transparent"}
  end

  defp background_pair(tuple) do
    primary = "#" <> elem(tuple, 0)

    secondary =
      if tuple_size(tuple) > 1,
        do: "#" <> elem(tuple, 1),
        else: primary

    {primary, secondary}
  end

  defp shuffle_tuple(prng, tuple) when tuple_size(tuple) <= 1 do
    {_raw, prng} = Prng.next(prng)
    {tuple, prng}
  end

  defp shuffle_tuple(prng, tuple) do
    {raw, prng} = Prng.next(prng)
    internal = Prng.new(Integer.to_string(raw))
    list = Tuple.to_list(tuple)
    last = length(list) - 1

    {shuffled, _internal} =
      Enum.reduce(last..1//-1, {list, internal}, fn i, {acc, p} ->
        {j, p} = Prng.integer(p, 0, i)
        vi = Enum.at(acc, i)
        vj = Enum.at(acc, j)

        acc =
          acc
          |> List.replace_at(i, vj)
          |> List.replace_at(j, vi)

        {acc, p}
      end)

    {List.to_tuple(shuffled), prng}
  end

  # -- SVG geometry transforms --------------------------------------------

  defp maybe_scale(body, 100), do: body

  defp maybe_scale(body, scale) do
    pct = (scale - 100) / 100
    tx = format_float(@canvas_center * pct * -1)
    ty = format_float(@canvas_center * pct * -1)
    sf = format_float(scale / 100)
    ["<g transform=\"translate(", tx, " ", ty, ") scale(", sf, ")\">", body, "</g>"]
  end

  defp maybe_flip(body, false), do: body

  defp maybe_flip(body, true) do
    ["<g transform=\"scale(-1 1) translate(", @neg_canvas_size_str, " 0)\">", body, "</g>"]
  end

  defp maybe_rotate(body, 0), do: body

  defp maybe_rotate(body, angle) do
    a = Integer.to_string(angle)

    [
      "<g transform=\"rotate(",
      a,
      ", ",
      @canvas_center_str,
      ", ",
      @canvas_center_str,
      ")\">",
      body,
      "</g>"
    ]
  end

  defp maybe_translate(body, 0, 0), do: body

  defp maybe_translate(body, tx, ty) do
    dx = format_float(@canvas_size * (tx / 100))
    dy = format_float(@canvas_size * (ty / 100))
    ["<g transform=\"translate(", dx, " ", dy, ")\">", body, "</g>"]
  end

  defp maybe_background(body, %{colors: {"transparent", _}}), do: body
  defp maybe_background(body, %{colors: {_, "transparent"}}), do: body

  defp maybe_background(body, %{colors: {primary, _secondary}, type: "solid"}) do
    [
      "<rect fill=\"",
      primary,
      "\" width=\"",
      @canvas_size_str,
      "\" height=\"",
      @canvas_size_str,
      "\" x=\"",
      @canvas_origin_str,
      "\" y=\"",
      @canvas_origin_str,
      "\" />",
      body
    ]
  end

  defp maybe_background(body, %{
         colors: {primary, secondary},
         type: "gradientLinear",
         rotation: rot
       }) do
    [
      "<rect fill=\"url(#backgroundLinear)\" width=\"",
      @canvas_size_str,
      "\" height=\"",
      @canvas_size_str,
      "\" x=\"",
      @canvas_origin_str,
      "\" y=\"",
      @canvas_origin_str,
      "\" />",
      "<defs><linearGradient id=\"backgroundLinear\" gradientTransform=\"rotate(",
      Integer.to_string(rot),
      " 0.5 0.5)\">",
      "<stop stop-color=\"",
      primary,
      "\"/>",
      "<stop offset=\"1\" stop-color=\"",
      secondary,
      "\"/>",
      "</linearGradient></defs>",
      body
    ]
  end

  defp maybe_clip(body, _radius, false), do: body

  defp maybe_clip(body, radius, _clip) do
    rx = format_float(@canvas_size * radius / 100)
    ry = rx

    [
      "<mask id=\"viewboxMask\"><rect width=\"",
      @canvas_size_str,
      "\" height=\"",
      @canvas_size_str,
      "\" rx=\"",
      rx,
      "\" ry=\"",
      ry,
      "\" x=\"",
      @canvas_origin_str,
      "\" y=\"",
      @canvas_origin_str,
      "\" fill=\"#fff\" /></mask>",
      "<g mask=\"url(#viewboxMask)\">",
      body,
      "</g>"
    ]
  end

  # -- final SVG wrapper ---------------------------------------------------

  @svg_open [
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 ",
    Integer.to_string(@canvas_size),
    " ",
    Integer.to_string(@canvas_size),
    "\" fill=\"none\" shape-rendering=\"auto\""
  ]

  defp wrap_svg(body, %{size: nil}) do
    [@svg_open, ">", body, "</svg>"]
  end

  defp wrap_svg(body, %{size: size}) do
    s = Integer.to_string(size)
    [@svg_open, " width=\"", s, "\" height=\"", s, "\">", body, "</svg>"]
  end

  # -- formatting ----------------------------------------------------------

  defp format_float(value) when is_float(value) do
    if value == Float.floor(value) do
      Integer.to_string(trunc(value))
    else
      Float.to_string(value)
    end
  end
end
