---
title: Stacked bar
group: Bar
order: 8
---

Each column is shown as a share of its own total, so the axis reads in percentages no matter how large the underlying numbers are.

```charty
{
  "title": "Source lines by release",
  "caption": "Share of the codebase per language",
  "type": "bar-stacked",
  "data": [
    {
      "label": "Swift",
      "value": [21400, 33800, 48210]
    },
    {
      "label": "Objective-C",
      "value": [28600, 19200, 12640]
    },
    {
      "label": "C",
      "value": [5200, 4900, 4380]
    },
    {
      "label": "Metal",
      "value": [420, 780, 1120]
    }
  ]
}
```

## Definition

```json
{
  "title": "Source lines by release",
  "caption": "Share of the codebase per language",
  "type": "bar-stacked",
  "data": [
    {
      "label": "Swift",
      "value": [21400, 33800, 48210]
    },
    {
      "label": "Objective-C",
      "value": [28600, 19200, 12640]
    },
    {
      "label": "C",
      "value": [5200, 4900, 4380]
    },
    {
      "label": "Metal",
      "value": [420, 780, 1120]
    }
  ]
}
```
