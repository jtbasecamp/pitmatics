# Pitmatics — Phase 1 Launch Guide

This is your start-to-finish guide to getting Pitmatics live and into the hands of beta testers. Treat it like a runbook, not a manifesto. Knock items off in order.

---

## What you have

1. `index.html` — the deployable web app. Single file, both engines (low-and-slow + hot-and-fast), works offline, no backend.
2. `calibration-log-template.md` — the data-collection template you and your two collaborators will use.

That's it. Phase 1 is intentionally tiny. Resist the urge to add anything before launch.

---

## Week 1 — Get it on the internet

### Step 1 — Test locally

Open `index.html` in your browser by double-clicking it. The whole app should work — both calculators, mode toggle, results timeline. If anything looks broken, fix it now before deploying.

### Step 2 — Deploy to Netlify (free, takes 5 minutes)

1. Go to **netlify.com** and create a free account
2. Click **"Add new site" → "Deploy manually"**
3. Drag the folder containing `index.html` into the upload zone
4. Netlify gives you a URL like `glittering-cookie-12345.netlify.app`
5. Click **"Site settings" → "Change site name"** and rename to `pitmatics` (so you get `pitmatics.netlify.app`)

You now have a live website. That's it. That's the deploy.

### Step 3 — Buy the domain (optional for Phase 1)

This is optional for beta, but $12/year and you can do it now if you want:

1. Buy `pitmatics.com` (or `.app`, or `.co`) from Namecheap, Cloudflare, or Porkbun
2. In Netlify, go to **Domain settings → Add custom domain**
3. Follow Netlify's instructions to point your DNS at them
4. SSL/HTTPS is automatic — Netlify handles it

**My recommendation:** if you can get `pitmatics.com`, grab it. If it's taken or expensive, `pitmatics.app` is a strong alternative.

---

## Week 2 — Polish and first calibration cooks

### Calibration cooks

Run **at least two cooks this week** following Pitmatics' schedule exactly. One should be a familiar cut (probably brisket or pork butt), one can be a hot-and-fast cook.

Log every detail in the calibration template. After each cook, write down:
- Was the predicted fire time right?
- Did the stall behave like the timeline said?
- Was the wrap timing reasonable?
- Did you serve on time?

Push fixes to the multipliers as you find issues. Re-deploy by re-uploading `index.html` to Netlify.

### Polish punch list

- [ ] Test on your phone — mobile is where most pitmasters will check the app while at the smoker
- [ ] Test in dark mode (the CSS already supports it — toggle your OS theme)
- [ ] Test the printable view (Cmd+P / Ctrl+P) — does it look reasonable?
- [ ] Update the feedback email link to a real address you check
- [ ] Add a favicon (a simple ember-orange dot is fine — same as the wordmark)

---

## Week 3 — Recruit beta pitmasters

### Goal: 10–20 testers

Post in:

- **r/smoking** (Reddit, ~1.5M members) — the biggest BBQ community on the internet
- **r/BBQ** (Reddit, ~750k members)
- **r/pelletgrills** (~150k) — directly relevant to your own setup
- **Smoking Meat Forums** (smokingmeatforums.com) — old-school but active
- **Facebook groups** — search "BBQ" + your region, plus brand-specific groups (Traeger Owners, Big Green Egg, etc.)

### The post template

> **Built a tool to answer the eternal BBQ question: "When do I light the fire?"**
>
> I've been working on a free tool called Pitmatics that takes your cut, weight, smoker, wrap method, and target serve time, and tells you when to fire up. Includes the stall, the wrap window, the rest — all of it.
>
> I'm looking for 10–20 pitmasters to cook with it over the next few weeks and tell me where the math is off. Free, no signup. Just looking for honest feedback.
>
> Link: [your domain]
> Feedback form: [your email]
>
> I'm a [your smoker] guy myself — built this because I was tired of "guess and pray" timing.

### What to do with feedback

- Reply to every single response in the first month. Every one.
- Track issues in a simple spreadsheet — what cut, what smoker, what was off
- Patterns of feedback matter more than individual reports — if three pellet-grill users say briskets run 1hr long, that's a multiplier change

---

## Week 4–5 — Calibration sprint

Now you have real data flowing in. This is the most important phase.

Spend roughly 50/50 time between:

- **Coding** — adjusting multipliers based on patterns you're seeing
- **Communicating** — replying to testers, asking follow-up questions, building relationships

The goal at the end of week 5: **every cut/smoker combination has been tested at least twice across the three of you and the beta testers**, and the deltas are mostly within ±30 min on long cooks.

---

## What success looks like at end of Phase 1

- [ ] Pitmatics is live at a real URL
- [ ] You and your two collaborators have logged 10+ cooks
- [ ] 10+ outside beta testers have used it
- [ ] You have 50+ data points across cut/smoker combinations
- [ ] Multipliers have been adjusted at least once per cut
- [ ] You have an email list of interested testers ready for Phase 2 launch
- [ ] You've identified the 2–3 most-requested features for Phase 2

If you hit those checkpoints, Phase 1 is a success regardless of how many users you have. **Validated math is the only deliverable that matters.**

---

## What NOT to do during Phase 1

These are the temptations that kill solo projects. Resist them.

- **Don't add a login system.** No accounts in Phase 1.
- **Don't add a database.** No saved cooks in Phase 1.
- **Don't charge money.** Free, frictionless beta only.
- **Don't promise features in social media replies.** Say "noted, in the backlog."
- **Don't redesign the UI.** It's fine. Ship and learn.
- **Don't optimize for SEO or traffic.** You want quality testers, not page views.
- **Don't worry about competitors.** Focus on your math.

---

## After Phase 1

Once the math is dialed, Phase 2 begins — track-a-cook live mode, email capture, push notifications, public launch. That's a different conversation for a different week.

For now: deploy, cook, log, iterate. The product is the math. The math is the product.

Light the fire.
