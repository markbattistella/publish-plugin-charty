---
title: Radar
group: Area
order: 16
---

Values are percentages plotted around a set of named axes. Give the axis names in `points` at the top level of the chart.

```charty
{
  "title": "SwiftUI against UIKit",
  "caption": "Team survey, percentage satisfied",
  "type": "radar",
  "points": ["Layout", "Animation", "Testing", "Tooling", "Docs", "Accessibility", "Performance", "Adoption"],
  "data": [
    {
      "label": "SwiftUI",
      "value": [88, 92, 61, 74, 70, 82, 66, 90]
    },
    {
      "label": "UIKit",
      "value": [64, 58, 79, 85, 88, 76, 91, 55]
    }
  ]
}
```

## Definition

```json
{
  "title": "SwiftUI against UIKit",
  "caption": "Team survey, percentage satisfied",
  "type": "radar",
  "points": ["Layout", "Animation", "Testing", "Tooling", "Docs", "Accessibility", "Performance", "Adoption"],
  "data": [
    {
      "label": "SwiftUI",
      "value": [88, 92, 61, 74, 70, 82, 66, 90]
    },
    {
      "label": "UIKit",
      "value": [64, 58, 79, 85, 88, 76, 91, 55]
    }
  ]
}
```
