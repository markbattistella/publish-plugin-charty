---
title: Scatter
group: Plot
order: 12
---

Points with no line between them. Set `numbers` to false where the shape of the data matters more than the readings.

```charty
{
  "title": "Incremental build times",
  "caption": "Seconds per commit, sampled",
  "type": "scatter",
  "options": {
    "numbers": false
  },
  "data": [
    {
      "label": "Debug",
      "value": [12, 9, 14, 8, 21, 11, 7, 16, 10, 13]
    },
    {
      "label": "Release",
      "value": [38, 44, 31, 52, 29, 47, 35, 41, 58, 33]
    }
  ]
}
```

## Definition

```json
{
  "title": "Incremental build times",
  "caption": "Seconds per commit, sampled",
  "type": "scatter",
  "options": {
    "numbers": false
  },
  "data": [
    {
      "label": "Debug",
      "value": [12, 9, 14, 8, 21, 11, 7, 16, 10, 13]
    },
    {
      "label": "Release",
      "value": [38, 44, 31, 52, 29, 47, 35, 41, 58, 33]
    }
  ]
}
```
