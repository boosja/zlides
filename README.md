# Zlides

A terminal slideshow written in Zig. Inspired by
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
