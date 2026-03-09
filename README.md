# DicebearLorelei

[![Elixir](https://img.shields.io/badge/elixir-~>_1.14-blueviolet.svg)](https://elixir-lang.org/)
[![Hex Version](https://img.shields.io/hexpm/v/dicebear_lorelei.svg)](https://hex.pm/packages/dicebear_lorelei)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/dicebear_lorelei/)
[![CI](https://github.com/cyril/dicebear_lorelei.ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/cyril/dicebear_lorelei.ex/actions)
[![License](https://img.shields.io/hexpm/l/dicebear_lorelei.svg)](https://github.com/cyril/dicebear_lorelei.ex/blob/main/LICENSE)

Pure Elixir port of the [DiceBear](https://dicebear.com) **Lorelei** avatar style — elegant illustrated vector avatars with detailed hair and facial features.

> Design by [Lisa Wischofsky](https://www.instagram.com/lischi_art/), licensed under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
> Code licensed under MIT.

![Example avatars](https://raw.githubusercontent.com/cyril/dicebear_lorelei.ex/3f82c86c1cf10d16f2bc20f5be10360b5fd070a1/img/banner.svg)

## Installation

Add `dicebear_lorelei` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dicebear_lorelei, "~> 0.1.0"}
  ]
end
```

## Features

- **Zero dependencies** — pure Elixir, no HTTP calls, no Node.js
- **Deterministic** — same seed always produces the same SVG
- **PRNG-compatible** — uses the exact same xorshift32 algorithm as DiceBear JS, so identical seeds produce matching component selections
- **134 SVG variants** — 48 hairstyles, 24 eyes, 27 mouths, 13 eyebrows, 6 noses, 5 glasses, 4 heads, 3 earrings, 2 beards, 1 freckles, 1 hair accessory
- **Fully customizable** — colors, component restrictions, probabilities, size, radius, background, flip, rotate, scale
- **O(n) on seed length** — PRNG consumes a fixed number of steps per avatar; only the seed hashing scales with input

## Usage

```elixir
# Generate an SVG string from a seed
svg = DicebearLorelei.svg("Felix")

# With options
svg = DicebearLorelei.svg("player42",
  size: 128,
  radius: 50,
  hair_color: ["8B4513"],
  skin_color: ["FFDAB9"]
)

# As a data URI for <img> tags
uri = DicebearLorelei.data_uri("user@example.com")
```

### In a Phoenix template

```heex
<img src={DicebearLorelei.data_uri(@user.email, size: 64, radius: 50)} alt="Avatar" />
```

Or generate once and cache:

```elixir
# In your User context
def avatar_svg(user) do
  DicebearLorelei.svg(user.email,
    size: 128,
    radius: 50,
    hair_color: ["2c1810", "4a2c0a", "8B4513", "654321"],
    skin_color: ["f5d0b0", "d4a574", "ffe0bd", "8d5524"]
  )
end
```

## Options

### Core options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:size` | integer | nil | Pixel size (width & height) |
| `:radius` | 0–50 | 0 | Border radius as percentage |
| `:scale` | 0–200 | 100 | Scale percentage |
| `:flip` | boolean | false | Mirror horizontally |
| `:rotate` | 0–360 | 0 | Rotation in degrees |
| `:translate_x` | -100–100 | 0 | Horizontal shift percentage |
| `:translate_y` | -100–100 | 0 | Vertical shift percentage |
| `:background_color` | list | [] | Hex colors, e.g. `["b6e3f4"]` |
| `:background_type` | list | ["solid"] | `"solid"` or `"gradientLinear"` |
| `:background_rotation` | list | [0, 360] | Angle range for gradient rotation |
| `:clip` | boolean | true | Clip to viewbox |

### Color options

All color options accept a list of hex strings. The PRNG picks one at random.

| Option | Default |
|--------|---------|
| `:hair_color` | `["000000"]` |
| `:skin_color` | `["ffffff"]` |
| `:eyes_color` | `["000000"]` |
| `:eyebrows_color` | `["000000"]` |
| `:mouth_color` | `["000000"]` |
| `:nose_color` | `["000000"]` |
| `:glasses_color` | `["000000"]` |
| `:earrings_color` | `["000000"]` |
| `:freckles_color` | `["000000"]` |
| `:hair_accessories_color` | `["000000"]` |

### Component options

Restrict which variants the PRNG can choose from:

```elixir
DicebearLorelei.svg("seed",
  eyes: [:variant01, :variant02, :variant03],
  mouth: [:happy01, :happy02, :happy03],
  hair: [:variant10, :variant20, :variant30]
)
```

### Probability options

Control whether optional components appear (0–100):

| Option | Default |
|--------|---------|
| `:beard_probability` | 5 |
| `:earrings_probability` | 10 |
| `:freckles_probability` | 5 |
| `:glasses_probability` | 10 |
| `:hair_accessories_probability` | 5 |

## Architecture

```
lib/
├── dicebear_lorelei.ex              # Public API
├── dicebear_lorelei/
│   ├── avatar.ex                    # Core generation engine
│   ├── prng.ex                      # xorshift32 PRNG (JS-compatible)
│   ├── options.ex                   # Default options & schema
│   ├── validation.ex                # Input validation at the boundary
│   └── components/
│       ├── renderer.ex              # Sub-component rendering
│       ├── hair.ex                  # 48 variants
│       ├── head.ex                  # 4 variants (composes sub-components)
│       ├── eyes.ex                  # 24 variants
│       ├── eyebrows.ex             # 13 variants
│       ├── mouth.ex                # 27 variants
│       ├── nose.ex                 # 6 variants
│       ├── beard.ex                # 2 variants
│       ├── glasses.ex              # 5 variants
│       ├── earrings.ex             # 3 variants
│       ├── freckles.ex             # 1 variant
│       └── hair_accessories.ex     # 1 variant
scripts/
└── extract_svg_data.mjs             # Re-generate components from npm
```

### Component composition

The rendering follows the same nesting as the original:

```
hair (SVG paths + color) → embeds head
  head (SVG paths + skin color) → embeds:
    ├── eyes
    ├── eyebrows
    ├── earrings (conditional)
    ├── freckles (conditional)
    ├── nose
    ├── beard (conditional)
    ├── mouth
    └── glasses (conditional)
```

## Re-generating components

If the upstream `@dicebear/lorelei` package is updated:

```bash
npm install @dicebear/lorelei
node scripts/extract_svg_data.mjs ./node_modules/@dicebear/lorelei
```

This will regenerate all Elixir component modules from the npm package.

## License

- **Code**: MIT
- **Avatar design**: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) by Lisa Wischofsky
