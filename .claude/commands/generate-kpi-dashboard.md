Generate a Dynatrace Gen 3 KPI dashboard and 30-minute BizEvents injector for the company named in $ARGUMENTS, then deploy both via dtctl.

Follow the full `dynatrace-kpi-dashboard-generator` skill instructions exactly:
1. Confirm the active dtctl context and tenant with the user before any writes.
2. Research 15–20 industry-specific KPIs for the named company.
3. Find a verified logo URL (curl check required).
4. Build the dashboard JSON (header split tiles, map tile above the fold, section dividers, KPI tiles, chart tiles with visualization variety).
5. Write the BizEvents injector JS (15–20 event types, 3,000–5,000 events/run, geo fields for the map).
6. Check for an existing injector workflow; add a task to it (never create a second workflow).
7. Deploy via `dtctl apply`, execute and verify ingestion with `dtctl exec` + DQL.
8. Write README.md, LEARNINGS.md, and SALES-PITCH.md into `dashboards/<Company>/`.
