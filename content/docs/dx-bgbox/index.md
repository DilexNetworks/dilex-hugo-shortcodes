---
title: "dx/bgbox – Background box"
summary: "Wrap content in a clean framed box with tone-based colours."
---

`dx/bgbox` is a simple wrapper for framing content — perfect behind photos, callouts, notes, or grouped content.

## Usage

- `tone` (optional): `neutral|info|warn|danger|success` (default: `neutral`)
- `title` (optional): heading text shown at the top of the box
- `class` (optional): extra CSS classes on the wrapper

## Examples

Each example below shows:

- **Code** (what you type in Markdown)
- **Renders** (what the shortcode outputs)

### Basic

**Code**

```go-html-template
{{</* dx/bgbox */>}}
This is a plain bgbox.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox >}}
This is a plain bgbox.
{{< /dx/bgbox >}}

### With tone + title

**Code**

```go-html-template
{{</* dx/bgbox tone="info" title="Note" */>}}
This is an **info** bgbox with a title.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="info" title="Note" >}}
This is an **info** bgbox with a title.
{{< /dx/bgbox >}}

### Tone gallery

These are the built-in tones. You can use them to match your site’s design language, and you can override the underlying colours via CSS variables.

#### Neutral

**Code**

```go-html-template
{{</* dx/bgbox tone="neutral" */>}}
Neutral tone.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="neutral" >}}
Neutral tone.
{{< /dx/bgbox >}}

#### Info

**Code**

```go-html-template
{{</* dx/bgbox tone="info" */>}}
Info tone.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="info" >}}
Info tone.
{{< /dx/bgbox >}}

#### Warn

**Code**

```go-html-template
{{</* dx/bgbox tone="warn" */>}}
Warn tone.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="warn" >}}
Warn tone.
{{< /dx/bgbox >}}

#### Danger

**Code**

```go-html-template
{{</* dx/bgbox tone="danger" */>}}
Danger tone.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="danger" >}}
Danger tone.
{{< /dx/bgbox >}}

#### Success

**Code**

```go-html-template
{{</* dx/bgbox tone="success" */>}}
Success tone.
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="success" >}}
Success tone.
{{< /dx/bgbox >}}

### Behind a photo

This is the common pattern: use `dx/bgbox` as a wrapper around `dx/photo`.
Notice that markdown is allowed in the caption.

**Code**

```go-html-template
{{</* dx/bgbox tone="neutral" */>}}
{{</* dx/photo src="test.jpg" caption_pos="below" */>}}**Montreal** - Place des Arts{{</* /dx/photo */>}}
{{</* /dx/bgbox */>}}
```

**Renders**

{{< dx/bgbox tone="neutral" >}}
{{< dx/photo src="test.jpg" caption_pos="below" >}}**Montreal** - Place des Arts{{< /dx/photo >}}
{{< /dx/bgbox >}}