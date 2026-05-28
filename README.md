# Pitmatics

**When do I light the fire?** → Pitmatics aims to answer that question.

A free, offline BBQ timing calculator that takes your cut, weight, smoker, wrap method, and target serve time, then tells you exactly when to fire up. Includes the stall, the wrap window, the rest — all of it.

**[→ Try it live](https://jtbasecamp.github.io/pitmatics/)**

## How it works

1. Pick your cut (brisket, pork butt, ribs, chuck roast, etc.)
2. Enter the weight, smoker type, and pit temp
3. Tell it when you want to serve
4. Get a timeline: light the fire at X o'clock, meat on at Y, wrap at Z, pull and rest at W, serve at the target time

The calculator accounts for:
- **The stall** — that 150–170°F plateau where heat stops penetrating
- **The wrap** — Texas crutch to power through once the stall hits
- **The rest** — time needed to reabsorb moisture after pulling
- **Smoker type, weather, meat grade, trim, starting temp, injection**

Everything is a multiplier on the base math: *hours/pound × weight × (all the factors that matter).*

## Using it

Open `index.html` in a browser. Works offline. Two calculators:
- **Low & Slow** — 225–275°F, for brisket, pork butt, ribs, chuck roast
- **Hot & Fast** — 325°F+, for faster cooks and thinner cuts

Optional **Fine-tune drawer** for grade, trim, weather, injection if you want to refine the estimate.

## Accuracy

Phase 1: Testing. You can help. Use the **calibration template** to log your cooks (actual fire time vs. predicted, stall behavior, wrap timing, serve time). Send feedback to [jtbasecamp@gmail.com](mailto:jtbasecamp@gmail.com). I'm not trying to mess up your cooks. Do what you'd normally do...just follow along with pitmatics and document the differences. This feedback, over time, will help fine tune pitmatics!

Goal for Phase 1: ±30 min accuracy. Goal for Phase 2: a learning loop that adjusts the math based on your actual cooks.

## Feedback

If you try this, **please log your cooks** using the calibration template and send results to jtbasecamp@gmail.com. Photos of the timeline during the cook are especially valuable.

---

Made by JT. MIT License (open to contributors).
