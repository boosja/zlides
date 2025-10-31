# Zlides

A terminal slideshow written in Zig (v0.15.1). Inspired by
[bbslideshow](https://github.com/teodorlu/bbslideshow).

## The Runnin's

- Build: `zig build`
  - Builds to `zig-out/bin/zlides`
- Run: `zig build run -- filepath-to-slides.txt`

## Example

`slides.txt`:
```
————————————————————

Title page

---

Second page

  Some content
---
End card
```

Then run: `zlides slides.txt`.

## Navigation

| Hotkey | Action                  |
|--------|-------------------------|
| ` `    | Next slide              |
| `j`    | Next slide              |
| `J`    | Jump 5 slides forward   |
| `k`    | Previous slide          |
| `K`    | Jump 5 slides backward  |
| `q`    | Quit                    |
