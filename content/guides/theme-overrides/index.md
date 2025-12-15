---
title: "Customizing colours"
summary: "Override dx/* default colours using CSS variables — no forks required."
---

This module exposes its colours as CSS custom properties (variables) using the `--dx-*` prefix (for example `--dx-bgbox-bg-info`). This makes it easy to theme the module without forking or copying any CSS.

## The rule: define your overrides after `dx.css`

CSS variables follow normal cascade rules. To override the defaults, define your values **after** the module stylesheet is loaded.

The simplest pattern is to add your own stylesheet in your site and include it *after* the module stylesheet in `baseof.html`:

```go-html-template
{{ with resources.Get "css/dx.css" }}
  {{ $css := . | minify | fingerprint }}
  <link rel="stylesheet" href="{{ $css.RelPermalink }}">
{{ end }}

{{ with resources.Get "css/site-overrides.css" }}
  {{ $css := . | minify | fingerprint }}
  <link rel="stylesheet" href="{{ $css.RelPermalink }}">
{{ end }}
```

## Global overrides

To change colours across the entire site, define overrides on `:root` in a stylesheet that loads after `dx.css`:

```css
:root {
  --dx-bgbox-bg-info: #e8f0ff;
  --dx-bgbox-border-info: #7aa2ff;
}
```

## Scoped overrides (only part of the site)

CSS variables cascade, so you can scope overrides to a specific container:

```css
.docs {
  --dx-bgbox-bg-info: #f0f7ff;
}
```

Then wrap the relevant content:

```html
<div class="docs">
  <!-- shortcodes content -->
</div>
```

Only bgboxes inside that container will use the overridden values.

## Dark mode overrides

You can override variables only for dark mode using a media query:

```css
@media (prefers-color-scheme: dark) {
  :root {
    --dx-bgbox-bg-neutral: #1f2328;
    --dx-bgbox-border-neutral: #3b4252;
  }
}
```

## Where to find the variables

Default values live in the module’s token file (for example `assets/css/dx-tokens.css`). If you’re unsure which variable controls which colour, start there and copy the ones you want to change into your override file.
