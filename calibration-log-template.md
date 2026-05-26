# Pitmatics Calibration Log

Use one row per cook. Share this with your two collaborators so all three of you are recording the same data points consistently — inconsistent data is worse than less data.

The whole point of Phase 1 is the **delta column**: the gap between what Pitmatics predicted and what actually happened. That delta drives every multiplier adjustment.

## How to use

Before the cook → fill in everything in the "Inputs" and "Pitmatics prediction" sections.
During the cook → log temp readings every 30–60 minutes in the notes column.
After the cook → fill in actual times, the delta, and notes on what went off-script.

## The columns

| Column | What goes in it | Why it matters |
|---|---|---|
| **Cook ID** | YYMMDD-initials (e.g. 260601-RT) | Unique reference for follow-up |
| **Pitmaster** | Who cooked it | So we know whose pit |
| **Cook date** | When the cook started | Calibration timeline |
| **Cut** | Brisket / pork butt / etc | Which engine row applies |
| **Weight (lbs)** | After trim | Feeds the math directly |
| **Grade** | Prime / Choice / Select | Beef only |
| **Trim** | Comp / Standard / Minimal | Beef only |
| **Shape** | Thick / Average / Flat | Visual call |
| **Injected** | Yes / No | Multiplier input |
| **Smoker** | Pellet / Offset / Kamado / Vertical | Big multiplier |
| **Smoker brand/model** | e.g. Traeger Ironwood 885 | For pattern-matching later |
| **Pit temp (°F)** | 225 / 250 / 275 / 300 | Target temp |
| **Actual pit temp range** | e.g. 245–258°F | Reality vs target |
| **Wrap method** | None / Foil / Paper | Multiplier input |
| **Wrap time (cook hour)** | e.g. hour 7 | When you actually wrapped |
| **Rest method** | Cooler / Holding oven | Math input |
| **Weather** | Ambient temp + wind notes | Multiplier input |
| **Starting temp** | Fridge / Room | Multiplier input |
| **Serve target** | Date + time you aimed for | The goal |
| **Pitmatics predicted fire time** | What the app told you | The prediction |
| **Pitmatics predicted total cook** | Hours range it showed | The prediction |
| **Actual fire time** | When you actually lit it | The reality |
| **Actual meat-on time** | When the meat went on | Useful for stall analysis |
| **Stall start time** | When internal hit ~155°F | Stall calibration |
| **Stall break time** | When internal cleared 165°F | Stall duration |
| **Pull time** | When you pulled at target | End of cook |
| **Pull internal temp** | Exact temp when pulled | Probe-tender vs number |
| **Total cook hours (actual)** | Meat-on to pull | The reality |
| **Actual serve time** | When food hit the table | Did the plan work? |
| **Delta — total cook** | Actual minus midpoint of prediction | The headline number |
| **Delta — serve time** | Minutes late or early | The user impact |
| **Result quality (1–5)** | Subjective — how good was it? | Spot the magic combinations |
| **Notes** | What surprised you, what you'd change | Calibration gold |

## Temp log section (per cook)

Keep this on a second sheet or below the main row. Every 30–60 min during the cook:

| Time | Cook hour | Internal temp (°F) | Pit temp (°F) | Notes (wrapped, spritzed, etc.) |
|---|---|---|---|---|

## What the data tells you over time

After 10–15 cooks across the three of you, look for patterns:

- **Consistent direction of delta on one smoker type** → adjust that smoker's multiplier
- **Stall lasting longer than predicted on one cut** → adjust stall window for that cut
- **Cold-weather cooks running 20%+ over prediction** → bump the cold multiplier
- **Injected briskets finishing 15% faster** → tighten the injection multiplier
- **One pitmaster's deltas consistently different** → either their pit is unusual, or their measurement method is, or there's a real signal in how their gear behaves

The goal isn't to make Pitmatics never wrong. The goal is to make it **predictably right within a useful range** — say, ±30 min on a 14-hour cook is excellent. ±2 hours is unusable.

## Ground rules for the three of you

1. **Log every cook, even the disasters.** Especially the disasters. A cook where the math was way off is more valuable than 10 cooks where it was right.
2. **Don't adjust Pitmatics' prediction in your head before logging it.** Write down what the app said, not what you "knew" it should be.
3. **Note the unusual stuff in the notes column.** Equipment quirks, weather changes mid-cook, opening the lid too much — all of it shapes the data.
4. **Share the log weekly.** A 15-minute Sunday review across the three of you spots patterns faster than reviewing alone.
