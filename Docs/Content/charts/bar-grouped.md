---
title: Grouped bar
group: Bar
order: 7
---

Several values per series groups them along the axis. Bars within a group sit close together, groups sit apart, and the legend names the series.

```charty
{
  "title": "Build time by configuration",
  "caption": "Seconds, clean build, across three releases",
  "type": "bar",
  "data": [
    {
      "label": "Debug",
      "value": [142, 128, 96]
    },
    {
      "label": "Release",
      "value": [318, 296, 241]
    }
  ]
}
```

## Definition

```json
{
  "title": "Build time by configuration",
  "caption": "Seconds, clean build, across three releases",
  "type": "bar",
  "data": [
    {
      "label": "Debug",
      "value": [142, 128, 96]
    },
    {
      "label": "Release",
      "value": [318, 296, 241]
    }
  ]
}
```
