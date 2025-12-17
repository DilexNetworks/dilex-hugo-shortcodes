---
title: dx/pullquote - Pullquote
summary: A styled pullquote for highlighting key quotations with optional author attribution.
---

## Overview

The `dx/pullquote` shortcode is used to visually highlight a quotation within prose.  
It is intentionally **JavaScript-free**, lightweight, and suitable for long-form writing.

It supports:

- optional author attribution
- alignment control
- color variants
- optional width constraints for editorial layouts

---

## Basic usage

```go-html-template
{{</* dx/pullquote >}}
To understand a thing is to be liberated from it.
{{< /dx/pullquote */>}}
```

{{< dx/pullquote >}}
To understand a thing is to be liberated from it.
{{< /dx/pullquote >}}

---

## With author attribution

```go-html-template
{{</* dx/pullquote author="John Berger" >}}
To understand a thing is to be liberated from it.
{{< /dx/pullquote */>}}
```

{{< dx/pullquote author="John Berger" >}}
To understand a thing is to be liberated from it.
{{< /dx/pullquote >}}

---


## Alignment

You can control alignment using the `align` parameter.

Supported values:

- `left`
- `center` (default)
- `right`

```go-html-template
{{</* dx/pullquote align="left" >}}
Photography is not about the thing photographed.
{{< /dx/pullquote */>}}
```

{{< dx/pullquote align="left" >}}
Photography is not about the thing photographed.
{{< /dx/pullquote >}}

---

## Colour variants

The pullquote supports predefined colour variants that map to CSS variables 
in the module.

Available variants:

- `ink` (default)
- `sun`
- `sky`
- `mint`
- `rose`

```go-html-template
{{</* dx/pullquote variant="mint" >}}
The camera is an instrument that teaches people how to see without a camera.
{{< /dx/pullquote */>}}
```

{{< dx/pullquote variant="mint" >}}
The camera is an instrument that teaches people how to see without a camera.
{{< /dx/pullquote >}}

> Variants are themeable. Users can override the CSS variables to match their site’s design.

---

## Constraining width

For editorial layouts, you can limit the maximum width using the `width` parameter.

```go-html-template
{{</* dx/pullquote width="30ch" >}}
A photograph is a secret about a secret.
{{< /dx/pullquote */>}}
```

{{< dx/pullquote width="30ch" >}}
A photograph is a secret about a secret.
{{< /dx/pullquote >}}

This works well for magazine-style layouts and side-aligned quotations.

---

## Full example

```go-html-template
{{</* dx/pullquote
    author="Susan Sontag"
    align="right"
    variant="ink"
    width="32ch"
>}}
Photographs objectify: they turn an event or a person into something that can be possessed.
{{< /dx/pullquote */>}}
```

{{< dx/pullquote
author="Susan Sontag"
align="right"
variant="ink"
width="32ch"
>}}
Photographs objectify: they turn an event or a person into something that can be possessed.
{{< /dx/pullquote >}}

---

## Design notes

- Uses semantic `<blockquote>` markup
- Author attribution is rendered with `<figcaption>`
- Inner content is passed through `markdownify`
- Decorative quotation marks are purely visual
- No JavaScript required
- Safe to use inside standard Markdown prose

---

## When to use `dx/pullquote`

Use it when you want to:

- emphasize a key idea
- visually break up long-form text
- add editorial polish without layout hacks

Avoid it for:

- long multi-paragraph quotations
- citations that require structured references or footnotes