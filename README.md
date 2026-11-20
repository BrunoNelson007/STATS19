# Road Collision Analysis: Is Darkness a Problem? (STATS19, 2025)

## The question
Manager at a council road safety team says: “We have budget for one intervention next year: street lighting or lower speed limits. Before Friday, tell me whether darkness is a real problem in our collision data.

## Data
DfT STATS19: collision 101,525 rows, vehicle 183,948 rows and casualty 127,883 rows. 2025 data

## Method
The three CSVs were loaded into staging tables
-1 values were replaced with null and dates was converted to ISO format
Validation - row counts matched and dates ran from 2025-01-01 to 2025-12-31, there were 0 orphans and the fan out check showed 101,525 collisions against 127.883 rows after the join

## Findings
Yes, darkness is a problem on unlit roads. In 2025, 37.0% of collisions on unlit rural roads were fatal or serious, against 30.2% in daylight on rural roads, and urban roads show the same pattern (29.6% against 22.8%). On rural roads the gap holds within every speed band, between 4.6 and 7.9 percentage points, so speed limits explain only part of it. Other factors such as road class, junction type and weather haven’t been checked, so this shows unlit roads are linked to more severe collisions, not that adding lighting would fix them.

## Limitations
Other factors like Road class, junction type and weather not controlled for, havent been checked if it widens or narrows the gap.

## Excel vs SQL
(Two or three results that match in both, and what each tool was easier for.)

## Files
README.md
sql/stats19_setup.sql, the setup script
sql/analysis_queries.sql, my queries
excel/, my workbook
