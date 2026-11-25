---
name: "plain-symbols"
description: "Strip unusual typographic symbols from texts and documents and keep only letters, digits and classic punctuation (. , - ! ? \" ' _ ( ) + : ;). Use when the user asks to clean, normalize or remove strange characters, dashes, smart quotes, emoji, bullets, arrows or invisible characters from a text, .txt, .md, .csv or .docx file, and when writing any text or document for this user that will be pasted or submitted elsewhere."
---

# Plain symbols

AI-written and copy-pasted text is full of characters a person rarely types: long dashes, curly quotes, the single-character ellipsis, non-breaking and zero-width spaces, bullets, arrows, check marks, emoji. They give away generated text and break some forms and plagiarism checkers. This skill replaces them with plain keyboard characters or removes them.

## What stays

Letters of any alphabet (Latin, Cyrillic and others), digits, spaces, line breaks, and:

- Strict mode: `. , - ! ? " ' _ ( ) + : ;`
- Classic mode (default): strict plus `/ % = & @ # $`
- `--markdown` (on automatically for .md): also `# * \` [ ] > |`, so headings, bold and tables survive
- `--keep "..."`: extra characters the user wants, for example `--keep "№°€"`

Apostrophe, colon and semicolon are in strict mode on purpose: without them "don't" becomes "dont" and lists lose their colons.

## What gets replaced

| Found | Becomes |
|---|---|
| long and short dashes, minus sign, non-breaking hyphen | `-` |
| curly double quotes, guillemets `« »`, `„ "` | `"` |
| curly single quotes, prime, backtick | `'` |
| ellipsis character | `...` |
| bullets and check marks at line start | `- ` |
| arrows | `-` |
| `×` | `x` |
| `½ ¼ ¾` | `1/2 1/4 3/4` (strict: `0.5 0.25 0.75`) |
| `€ £ ₽ ₴ ₸` | `EUR GBP RUB UAH KZT` |
| `°C`, `°F` | ` C`, ` F` |
| `№` | `N` |
| superscript and circled digits | plain digits |
| non-breaking, thin and other special spaces, tabs | normal space |
| zero-width characters, soft hyphen, BOM, direction marks, emoji variation selectors | removed |
| emoji, `™ ®`, other decorative symbols | removed |

Double spaces left after removal are collapsed, and spaces before `. , ! ? : ; )` are dropped. Indentation at line start is kept.

## How to run

Script: `scripts/clean_symbols.py` (Python 3, standard library; .docx needs python-docx).

```bash
python3 scripts/clean_symbols.py input.txt -o output.txt
python3 scripts/clean_symbols.py essay.docx            # writes essay.clean.docx, formatting kept
python3 scripts/clean_symbols.py notes.md -o notes.md  # markdown mode on automatically
python3 scripts/clean_symbols.py input.txt --mode strict --keep "№"
python3 scripts/clean_symbols.py input.txt --report-only
echo "text" | python3 scripts/clean_symbols.py -
```

The report goes to stderr: every character that was replaced or removed, with its count and Unicode name.

For .docx the script edits text run by run, so bold, italics, styles, tables, headers and footers stay as they were. A symbol split across two runs is rare but possible; check the report.

For PDF, convert to text or .docx first (pdf skill), clean, then rebuild. Don't run the script on HTML, code, JSON or LaTeX: it would strip `< > { } [ ] \` that the syntax needs. For those, clean only the prose by hand.

## After the script

1. Read the "Check these lines" part of the report. It lists lines where a symbol that carries meaning was removed: `≈ ≤ ≥ ≠ ± ° ∞ ‰ § < > ~ * [ ]` and similar. Rewrite each in words in the language of the text: "≈5 km" becomes "about 5 km" / "около 5 км", "≥ 18" becomes "18 or more" / "от 18". Don't leave a bare number where a sign used to be.
2. Look at the places where a long dash was. A dash in the middle of a sentence often reads better as a comma, colon or full stop than as a hyphen with spaces. Fix them by hand when the hyphen looks wrong.
3. Quotes: guillemets in Russian or Ukrainian text become straight `"`. If the user wants to keep `« »`, rerun with `--keep "«»"`.
4. Tell the user in one or two lines what was changed (counts from the report) and anything you rewrote by hand.

Pasting text in chat with no file: run the script on stdin or apply the table above directly, then give back the cleaned text.

## When writing text yourself

If this user asks for a text, essay, document or message, write it without these symbols in the first place: hyphen `-` instead of long dashes (sparingly, prefer a comma or colon), straight quotes, three dots, `- ` for list items, no emoji, no arrows, no check marks. Run the script on any file you produce before handing it over and confirm the report is empty or only shows what the user allowed.
