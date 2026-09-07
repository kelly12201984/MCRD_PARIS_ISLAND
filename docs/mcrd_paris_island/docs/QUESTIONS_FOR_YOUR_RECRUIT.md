# Questions for your son

You said you need to find out a bunch more from him. Here's a structured way to do it.

**How to use this:** don't run it as an interview — play the vertical slice together
first, for ten minutes, then ask. Answers about a thing he has just *played* are worth
ten times more than answers about a thing he is imagining. "What was boring?" after a
playtest is the most valuable question in game development.

Answers go in `docs/ANSWERS.md`, or just get scribbled into this file. Either is fine.
What matters is writing them down, because you will both forget what you agreed on.

---

## Round 1 — After playing the slice

Ask these first. They're grounded in something concrete.

1. **What was the best moment?** (Even if it was only mildly good.)
2. **When were you bored?** Point at the exact second.
3. **Did the drill instructor feel scary, annoying, or funny?** Which did you *want*?
4. **Was it too fast or too slow?** — this one maps directly to `Config.Drill.ResponseWindow`,
   so you can change it in front of him and replay. Do that. It's the moment he
   realizes the game is *yours to control*, and it's usually when kids get hooked.
5. **What did you expect to happen that didn't?**

## Round 2 — Pinning down "realistic"

This is the important one. "Realistic" means four different games (see `DESIGN.md`).

6. **Name a game that feels the way you want this to feel.** Then: *which part* of it?
7. **Realistic like — you have to actually learn how to do drill? Or realistic like —
   it looks like real life?**
8. **Should you be able to fail?** If you mess up badly, what happens — do you get
   yelled at, sent back a week, kicked out?
9. **Is the drill instructor a real person playing, or the computer?**
10. **Do you want to *become* a drill instructor after you graduate?**

## Round 3 — Scope (ask gently)

Kids describe finished games. That's not a problem — it's a roadmap, and your job is
sequencing it, not shrinking it.

11. **If we could only build ONE more thing this month, what is it?**
12. **What's the moment the game is building toward?** (There should be one. In the
    real thing it's the Eagle, Globe and Anchor ceremony.)
13. **How long should one round last before you'd want to stop?**
14. **Is this a game you play alone, or with friends?** How many?
15. **What happens when you come back the next day — do you keep your progress?**

## Round 4 — What he wants to *do* on the project

Worth asking outright. He may want to build, not just direct.

16. **Do you want to write some of it, design the levels, or come up with what the
    drill instructor says?**
17. **Do you want to be the one who decides if it's fun?** (Say yes. Making him the
    design authority on fun, with you as the engineer, is a genuinely good split and
    he'll take it seriously.)

---

## Good first jobs for him

Each of these is real, shippable, and requires zero engineering support:

- **`src/shared/CommandCatalog.lua`** — pure data. He can add commands and write every
  line the drill instructor shouts. This is the highest-leverage file in the repo for a
  non-programmer and it's *his*.
- **`src/shared/Config.lua`** — every tuning number. Let him balance the difficulty.
- **`docs/DESIGN.md`** — have him write the Phase 3 section describing graduation.

## One note on the DI dialogue

Real drill instructors swear. The game can't. Frame this to him as a constraint that
makes the writing *better*, not weaker — the funniest and most quotable DI lines are
the creative ones, not the profane ones. Give him the rule up front and let him work
inside it, rather than editing his lines afterward.

## And a scheduling note

The strongest predictor of this project surviving is a **fixed, short, recurring
session** — 45 minutes every Saturday beats a heroic eight-hour weekend that never
happens again. End every session with something playable, even if it's barely changed.
