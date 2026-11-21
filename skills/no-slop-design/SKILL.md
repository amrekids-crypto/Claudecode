---
name: "no-slop-design"
description: "Use for any visual output: website, app screen, landing page, artifact, slide, poster, chart or inline visual, and when asked to fix or de-slop an existing page. Picks a real design direction and audits the result against known AI-slop tells."
---

# No-slop design

Models drift to the median of their training data. The result is the "AI slop" look: Inter, purple gradient, centered hero, three icon cards. The fix is to make real decisions before writing any code, then audit against a list of known tells.

Sources this is built from: Anthropic's "Prompting for frontend aesthetics" cookbook, Refactoring UI (Wathan & Schoger), Adrian Krebs' scoring of 1,590 Show HN pages for AI patterns (Apr 2026), designer catalogs of AI UI tells, and the "20 niche UI tricks to fix an AI slop website" checklist (short video, built on "unslop" by Damir Sokolovsky, @heydamir on X).

## Step 1. Decide before building

Write these down in 3-4 short lines before any code or layout:

1. Context: what is this, who looks at it, what one thing should they do or understand.
2. Direction: one concrete reference, never a mood word. Good: "Swiss railway timetable", "1970s NASA manual", "Monocle magazine spread", "Japanese pharmacy packaging", "Bloomberg terminal", "Penguin paperback cover", "Linear changelog". Bad: "modern", "clean", "sleek", "premium".
3. Type: one display face + one text face (or one family used decisively). State them.
4. Palette: one dominant color, one sharp accent, neutrals. Tied to the topic, not to "tech".
5. Bright moment: the one visual that only this subject could have (see Step 8).

If the person or an existing brand/design system already sets any of this, use theirs and skip that line.

## Step 2. Hierarchy first, decoration last

- Build the layout in grayscale. Hierarchy must come from size, weight, spacing and position. Add color only after it reads.
- Not everything is important. Pick the one primary element per screen/slide and de-emphasize the rest (lighter color, smaller size), instead of boosting everything.
- One main action per screen. One filled button in the accent color; everything else is a ghost/outline button or a text link. Two or three equally loud buttons side by side is a tell. The nav "Sign up" button should be quieter than the hero CTA, not a second bright pill.
- Use extremes for contrast: weights like 300 vs 800, size jumps of 2.5-3x between display and body, not 1.2x.
- Everything on a 4-point grid: spacing (4/8/12/16/24/32/48/64/96), font sizes, line heights, radii, icon sizes. Odd values like 13px, 37px, 22px next to each other are a tell. Related things close, groups far apart. Start with too much white space, then remove.
- Left-align by default. Centering every block (hero, section heads, cards, footer) is a tell. A left-aligned text column of 45-75 characters, with the visual on the other side, reads as designed. Center only a short, single focal moment.
- Labels are a last resort. "12 tasks" beats "Tasks: 12".
- Squint test: blurred, the order of importance should still be obvious.

## Step 3. Typography

Never as the main face: Inter, Roboto, Open Sans, Lato, Arial, Helvetica, system-ui. Also avoid the fonts LLMs fall back to when told to avoid Inter: Space Grotesk, Geist, Instrument Serif, Poppins, Montserrat.

Pick by direction (examples, not a menu to rotate through):
- Editorial: Fraunces, Newsreader, Crimson Pro, Source Serif 4, Literata
- Grotesk with character: Bricolage Grotesque, Familjen Grotesk, Schibsted Grotesk, Hanken Grotesk
- Technical: IBM Plex Sans/Mono, JetBrains Mono
- Expressive display: Syne, Unbounded, Darker Grotesque, Big Shoulders
- Cyrillic needed: check support first. Good options: IBM Plex, Literata, Onest, Golos UI, Manrope, PT Serif, Commissioner.

Pairing: high contrast is interesting (serif display + plain sans, or grotesk + mono). Don't put one italic serif accent word inside a sans headline, that's a tell.

- A heavy 700-800 sans headline in Title Case is the default slop hero. A large headline at regular weight (400) in sentence case often looks more deliberate.
- Sentence case for headings and buttons. No Title Case On Every Word.
- No tiny all-caps letter-spaced labels as section markers. If a small label is needed, use sentence case at body size or one step below.

## Step 4. Color

- Banned by default: purple/indigo/violet as primary, purple-to-blue or purple-to-pink gradients, gradient-filled headline text, Tailwind indigo-500/600 (#6366f1, #4f46e5), #667eea to #764ba2.
- Also avoid navy + teal + orange and cream + serif as defaults; they became the second-wave slop.
- Dominant color with a sharp accent beats an evenly spread rainbow palette. Save the accent for the main button and the bright moment; if it appears everywhere, it stops meaning anything.
- Take color from the subject: a bakery, a law firm and a crypto tool should never share a palette.
- Gradients only when they mean something (light, heat, time). No decorative glows, no colored box-shadows, no glow around buttons or cards.
- Dark mode is a choice, not a default. If dark, use a near-black tinted toward the palette (warm or cool), not pure #000 or a purple-navy. Body text contrast at least 4.5:1.
- Use CSS variables for every color.

## Step 5. Layout and components

Avoid these patterns unless the content truly demands them:
- Centered hero in a generic sans with a small pill badge above the H1 ("✨ Introducing X 2.0 →", often pulsing)
- Hero, then 3 identical feature cards with an icon on top, then testimonials, then CTA, then footer
- Glossy gradient orb or blob behind the hero or CTA; blurred "aurora" blobs; floating 3D shapes; glassmorphism
- Emoji in nav links, buttons, headings or the logo (✨ Features, 🔥 Changelog, Sign up 🚀, "with AI ✨")
- Fake social proof: a stack of avatar circles + ★★★★★ + "Loved by 10,000+ users" with no real source
- Stat banner as filler: "10x · 99.9% · 24/7" with tiny captions. Keep a number only if it is real, sourced and specific
- Cards inside cards; every piece of content boxed in a rounded card with soft shadow
- An icon in a tinted rounded square on top of every card
- Colored stripe on the top or left edge of cards
- Pill radius on everything. A large radius (20-26px+) on buttons, inputs, cards and images at once is a tell. Pick one small radius (2-8px) and use it everywhere; full pills only for real tags/chips
- Numbered 1-2-3 step rows used as filler
- Pricing table with the middle plan lifted
- Fully rounded button with an arrow icon
- Placeholders like "Acme", "John Doe", "Lorem ipsum", round fake numbers

Prefer instead: asymmetric grids, real content density, tables and rules instead of rows of cards, one strong image or typographic moment, alignment to a visible grid, a real piece of the product UI (a list, a search field with a real query, a log) instead of a mock dashboard full of colored bars.

## Step 6. Copy: say what it does, cut what means nothing

The headline says what the thing does for the reader, in plain words. Test: could a stranger tell from the headline alone what the product is? "Supercharge squirrel watching with AI" fails. "Know every squirrel in your yard by name" passes.

- No hype words: supercharge, revolutionize, unleash, transform, next-gen, cutting-edge, AI-powered, effortless, seamless, all-in-one, "everything you need", "10x your". Replace each with the concrete thing that happens.
- Body copy uses specifics from the subject: names, times, counts, a real scenario ("logs every visit, from Nutmeg's 6 a.m. raid to the grey you've never seen before").
- Cards must say something. Generic titles like "Smart Detection / Instant Insights / Community Hub" fit any product. Each card title should be a claim only this product can make ("Knows who's who", "Alerts that matter", "A log of every visit"). If three cards could be swapped onto another site unchanged, rewrite them or replace them with a table or list.

Filler captions are an AI-slop tell as strong as the purple gradient. Models add small text everywhere to make a screen look "finished". It clutters the interface and pushes the real content down.

Test for every piece of text that isn't the main content (labels, captions, eyebrows, subtitles, hints, badges, chips, footers): what does the reader lose if it's gone? If nothing, or if it repeats something already visible, delete it.

Typical offenders:
- Eyebrow labels above headings that just name the section: "FEATURES", "OUR MISSION", "HOW IT WORKS", "Section 01"
- Subtitles that restate the heading in more words
- Captions under icons, images or charts that repeat the title or describe what is plainly visible
- Helper text and placeholders that repeat the field label ("Email" + "Enter your email address")
- Decorative microcopy: "Scroll to explore", "Crafted with care", "Powered by AI", "Made for teams", "v2.0 · Beta"
- Status chips and badges with no function: "Live", "New", "Popular", "✓ Verified" on things nobody verified
- Tooltips that repeat the button text; "Click here" / "Learn more" links with nothing behind them
- Taglines under logos, slogans in footers, "© 2026 All rights reserved" on a one-off artifact
- Axis titles, legends and units on a chart that already says them in its title, or a legend for a single series
- Fake meta lines: "Last updated just now", "3 min read", "Trusted by 10,000+ teams" with no real basis

Keep a label only when the value is ambiguous without it (units, a field the user fills in, a column header in a real table).

## Step 7. Motion and background

- Static by default. No bouncing, floating, pulsing or wiggling loops on buttons, badges, icons or blobs. Hover states change color or underline, not scale and bounce.
- One orchestrated moment (a single staggered reveal on load) beats scattered micro-animations. Respect prefers-reduced-motion.
- Backgrounds can carry atmosphere through texture, a subtle pattern or a tone shift that fits the direction. Not by default gradients.

## Step 8. One bright moment

After cutting the slop, a page can go flat. Give it one thing worth looking at, and only one. It must come from the subject, not from a stock effect.

Examples: a dithered or halftone illustration of the subject with small mono annotations pointing at it ("Nutmeg · 6:12 am", "Took 3 peanuts", "Regular since March"); a real product screen with real data; an oversized number that matters; a map, a timetable, a specimen. The accent color can live here. Everything around it stays quiet so it reads.

## Step 9. Slides and documents

- Only what the speaker points at goes on the slide. Short 2-3 word titles, sentence case.
- One idea per slide. Every number has a source in a small caption.
- No decoration that carries no information (icons, DNA helixes, progress bars, footers with deck title).
- No subtitles, eyebrows or summary lines that only restate the title or what the speaker says aloud.
- Tables and simple rules instead of rows of identical shadowed boxes.

## Step 10. De-slopping an existing page

When asked to fix a page someone else (or a model) already made, go in this order, re-checking after each group:

1. Effects: purple gradient, gradient text, glow, glossy blob, emoji in nav/buttons.
2. Hero: kill the pill badge, rewrite the headline to say what it does, remove hype words, left-align, keep one main button, remove fake avatars/stars.
3. System: put sizes and spacing on the 4-point grid, one small radius instead of pills, replace Inter/default font, drop heavy Title Case.
4. Sections: remove the stat banner, tiny all-caps eyebrows and icon boxes; make each card say something specific.
5. Finish: stop all bouncing and pulsing, then add one bright moment.

Keep the content and structure the person wants. Change the decisions, not the product.

## Step 11. Audit before delivering

Go through this list and count the hits:

1. Purple/indigo primary or purple gradient
2. Gradient text
3. Glow or colored shadow
4. Glossy blob, aurora, glass, floating 3D shape
5. Emoji in nav, buttons, headings
6. Pill badge above the headline
7. Headline doesn't say what it does
8. Hype words
9. Everything centered
10. More than one loud button
11. Fake reviews or avatar/star proof
12. Off-grid sizes and spacing
13. Pill corners on everything
14. Inter or another default font as main face
15. Filler stat banner
16. Tiny all-caps labels
17. Icon in a box on every card
18. Generic cards that fit any product
19. Bouncing, pulsing, floating motion
20. No bright moment, or more than one competing for attention

Also count: cards in cards, colored card stripe, placeholder names, filler captions/labels that fail the Step 6 test.

- 0-1: ship it.
- 2+: fix the worst ones and recount.

Then ask: would a human designer with this exact reference make these exact choices? Could someone tell this is AI from a two-second look? If yes, change the direction, not just the colors.

## Variety

Don't converge across requests. Two different projects should not look like siblings. Vary light/dark, type families and structure from one task to the next. The fixes above are not a new template: a near-black page with one amber button and a mono-annotated illustration will become the next slop if every project gets it.
