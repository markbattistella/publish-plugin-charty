---
title: Area (layered)
group: Area
order: 15
---

Series are layered rather than stacked, each drawn partly transparent so the ones behind stay visible.

```charty
{
  "title": "Downloads by platform",
  "caption": "Layered, not summed",
  "type": "area",
  "data": [
    {
      "label": "iOS",
      "value": [5200, 6300, 8500, 7400, 9200, 8300, 9900, 11400]
    },
    {
      "label": "macOS",
      "value": [1200, 2300, 4500, 3400, 5200, 4300, 5900, 7400]
    }
  ]
}
```

## Definition

```json
{
  "title": "Downloads by platform",
  "caption": "Layered, not summed",
  "type": "area",
  "data": [
    {
      "label": "iOS",
      "value": [5200, 6300, 8500, 7400, 9200, 8300, 9900, 11400]
    },
    {
      "label": "macOS",
      "value": [1200, 2300, 4500, 3400, 5200, 4300, 5900, 7400]
    }
  ]
}
```
