---
title: Line (multiple)
group: Plot
order: 11
---

Several series share one axis. Hovering the legend fades the others so a single line can be followed across the chart.

```charty
{
  "title": "Tests over time",
  "caption": "Count per release",
  "type": "line",
  "data": [
    {
      "label": "Unit",
      "value": [312, 388, 441, 507, 596, 664, 712, 803]
    },
    {
      "label": "Integration",
      "value": [48, 62, 71, 90, 104, 118, 131, 149]
    },
    {
      "label": "UI",
      "value": [22, 24, 31, 36, 41, 44, 52, 58]
    }
  ]
}
```

## Definition

```json
{
  "title": "Tests over time",
  "caption": "Count per release",
  "type": "line",
  "data": [
    {
      "label": "Unit",
      "value": [312, 388, 441, 507, 596, 664, 712, 803]
    },
    {
      "label": "Integration",
      "value": [48, 62, 71, 90, 104, 118, 131, 149]
    },
    {
      "label": "UI",
      "value": [22, 24, 31, 36, 41, 44, 52, 58]
    }
  ]
}
```
