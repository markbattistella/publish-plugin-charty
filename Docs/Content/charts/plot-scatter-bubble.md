---
title: Bubble
group: Plot
order: 13
---

A scatter chart where the point size scales with the value, so magnitude reads without needing the axis.

```charty
{
  "title": "Package downloads",
  "caption": "By release, weighted by size",
  "type": "bubble",
  "options": {
    "numbers": false
  },
  "data": [
    {
      "label": "Charty",
      "value": [2455, 7665, 4700, 7000, 4430, 8142]
    },
    {
      "label": "Publish",
      "value": [6321, 8765, 2230, 8730, 14430, 9142]
    }
  ]
}
```

## Definition

```json
{
  "title": "Package downloads",
  "caption": "By release, weighted by size",
  "type": "bubble",
  "options": {
    "numbers": false
  },
  "data": [
    {
      "label": "Charty",
      "value": [2455, 7665, 4700, 7000, 4430, 8142]
    },
    {
      "label": "Publish",
      "value": [6321, 8765, 2230, 8730, 14430, 9142]
    }
  ]
}
```
