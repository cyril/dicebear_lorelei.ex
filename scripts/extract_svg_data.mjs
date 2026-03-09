#!/usr/bin/env node
/**
 * extract_svg_data.mjs
 *
 * Extracts SVG path data from @dicebear/lorelei and generates Elixir modules
 * that return iodata (lists) instead of concatenated strings.
 *
 * Usage: node scripts/extract_svg_data.mjs [path-to-lorelei-package]
 */

import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, "..", "lib", "dicebear_lorelei", "components");
const PKG_PATH = process.argv[2] || "/tmp/package";

function makeColorProxy() {
  return new Proxy({}, { get: (_, p) => `__COLOR_${String(p)}__` });
}

function makeComponentProxy() {
  return new Proxy({}, {
    get: (_, p) => ({ name: String(p), value: () => `__COMPONENT_${String(p)}__` }),
  });
}

function extractVariants(jsFilePath, exportName) {
  let source = readFileSync(jsFilePath, "utf-8");
  source = source.replace(/import\s*\{[^}]+\}\s*from\s*['"][^'"]+['"];?\s*/g, "");
  const wrapped = `
    const escape = { xml: (s) => String(s) };
    const __e = {};
    ${source.replace(`export const ${exportName}`, `__e.${exportName}`)}
    return __e.${exportName};
  `;
  let collection;
  try { collection = new Function(wrapped)(); }
  catch (e) { console.error(`  Error: ${e.message}`); return {}; }

  const variants = {};
  const colors = makeColorProxy();
  const components = makeComponentProxy();
  for (const [name, fn] of Object.entries(collection)) {
    if (typeof fn !== "function") continue;
    try { variants[name] = fn(components, colors); }
    catch (e) { console.error(`  Error in ${name}: ${e.message}`); }
  }
  return variants;
}

function parseSvg(svg) {
  const parts = [];
  const re = /__(?:COLOR|COMPONENT)_([a-zA-Z0-9]+)__/g;
  let last = 0, m;
  while ((m = re.exec(svg)) !== null) {
    if (m.index > last) parts.push({ t: "l", v: svg.slice(last, m.index) });
    parts.push({ t: m[0].startsWith("__COLOR_") ? "c" : "k", v: m[1] });
    last = re.lastIndex;
  }
  if (last < svg.length) parts.push({ t: "l", v: svg.slice(last) });
  return parts;
}

function esc(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/#\{/g, "\\#{");
}

function camelToSnake(n) { return n.replace(/([A-Z])/g, "_$1").toLowerCase().replace(/^_/, ""); }
function toPascal(n) { return camelToSnake(n).split("_").map(s => s[0].toUpperCase() + s.slice(1)).join(""); }

function genModule(componentName, variants) {
  const mod = toPascal(componentName);
  const entries = Object.entries(variants);
  const atoms = entries.map(([n]) => `:${n}`).join(", ");

  const fns = entries.map(([name, svg]) => {
    const parts = parseSvg(svg);
    const usesComponents = parts.some(p => p.t === "k");
    const usesRenderer = usesComponents;
    const componentsParam = usesComponents ? "components" : "_components";

    const elems = parts.map(p => {
      if (p.t === "l") return `      "${esc(p.v)}"`;
      if (p.t === "c") return `      colors.${p.v}`;
      return `      Renderer.render(components, :${p.v}, colors)`;
    });

    let body;
    if (elems.length === 0) {
      body = `    []`;
    } else if (elems.length === 1 && parts[0].t === "l") {
      body = `  ${elems[0].trim()}`;
    } else {
      body = `    [\n${elems.join(",\n")}\n    ]`;
    }

    return `  def svg(:${name}, ${componentsParam}, colors) do\n  ${body}\n  end`;
  }).join("\n\n");

  // Only alias Renderer if at least one variant uses it
  const anyUsesRenderer = entries.some(([, svg]) => parseSvg(svg).some(p => p.t === "k"));
  const aliasLine = anyUsesRenderer
    ? "\n  alias DicebearLorelei.Components.Renderer\n"
    : "";

  return `defmodule DicebearLorelei.Components.${mod} do
  @moduledoc false
${aliasLine}
  @variants [${atoms}]

  def variants, do: @variants

${fns}

  def svg(_unknown, _components, _colors), do: []
end
`;
}

function main() {
  const dir = join(PKG_PATH, "lib", "components");
  mkdirSync(OUTPUT_DIR, { recursive: true });

  // Renderer module (replaces helpers.ex)
  writeFileSync(join(OUTPUT_DIR, "renderer.ex"), `defmodule DicebearLorelei.Components.Renderer do
  @moduledoc false

  @doc false
  @spec render(map(), atom(), map()) :: iodata()
  def render(components, component_name, colors) do
    case Map.get(components, component_name) do
      {variant, module} -> module.svg(variant, components, colors)
      nil -> []
    end
  end
end
`);
  console.log("✓ renderer.ex");

  const files = [
    ["hair.js", "hair"], ["head.js", "head"], ["eyes.js", "eyes"],
    ["eyebrows.js", "eyebrows"], ["mouth.js", "mouth"], ["nose.js", "nose"],
    ["beard.js", "beard"], ["glasses.js", "glasses"], ["earrings.js", "earrings"],
    ["freckles.js", "freckles"], ["hairAccessories.js", "hairAccessories"],
  ];

  let total = 0;
  for (const [file, name] of files) {
    process.stdout.write(`${name}... `);
    const variants = extractVariants(join(dir, file), name);
    const count = Object.keys(variants).length;
    if (count === 0) { console.log("⚠ 0"); continue; }
    const snake = camelToSnake(name);
    writeFileSync(join(OUTPUT_DIR, `${snake}.ex`), genModule(name, variants));
    console.log(`✓ ${count}`);
    total += count;
  }
  console.log(`\n✅ ${total} variants → ${OUTPUT_DIR}`);
}

main();
