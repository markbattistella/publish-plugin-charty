---
title: Custom colours
group: Other
order: 18
---

Any series can override the generated palette with `colour` (or `color`). Anything CSS understands works, and the rest of the chart carries on using the theme.

```charty
{
  "title": "Platform colours",
  "caption": "Each series pinned to its own colour",
  "type": "bar",
  "data": [
    {
      "label": "Swift",
      "value": 48210,
      "colour": "#F05138"
    },
    {
      "label": "Objective-C",
      "value": 12640,
      "colour": "#438EFF"
    },
    {
      "label": "C",
      "value": 4380,
      "colour": "#A8B9CC"
    },
    {
      "label": "Metal",
      "value": 1120,
      "colour": "#8E44AD"
    }
  ]
}
```

## Definition

```json
{
  "title": "Platform colours",
  "caption": "Each series pinned to its own colour",
  "type": "bar",
  "data": [
    {
      "label": "Swift",
      "value": 48210,
      "colour": "#F05138"
    },
    {
      "label": "Objective-C",
      "value": 12640,
      "colour": "#438EFF"
    },
    {
      "label": "C",
      "value": 4380,
      "colour": "#A8B9CC"
    },
    {
      "label": "Metal",
      "value": 1120,
      "colour": "#8E44AD"
    }
  ]
}
```
