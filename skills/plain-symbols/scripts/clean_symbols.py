#!/usr/bin/env python3
"""Replace or remove unusual symbols in text, keeping letters, digits and classic punctuation.

Usage:
  clean_symbols.py INPUT [-o OUTPUT] [--mode classic|strict] [--markdown] [--keep CHARS] [--report-only]
  echo "text" | clean_symbols.py -

Supports .txt, .md, .csv and other plain text, plus .docx (needs python-docx).
Prints a report of every replaced or removed character to stderr.
"""
import argparse
import collections
import sys
import unicodedata

STRICT = set('.,-!?"_()+' + "':;")
CLASSIC = STRICT | set("/%=&@#$")
# Symbols that carry meaning. Removing them can change the sense, so their lines are listed for review.
MEANINGFUL = set("\u2248\u2264\u2265\u2260\u00b1\u00b0\u221e\u2211\u221a\u2030\u00a7\u00b6\u2020\u2021<>~^|*{}[]\\")
MARKDOWN = set("#*`[]>|")

# Replacements applied before filtering. Order matters for multi-char keys.
REPLACE = [
    ("\u2014", "-"), ("\u2013", "-"), ("\u2012", "-"), ("\u2015", "-"),
    ("\u2212", "-"), ("\u2010", "-"), ("\u2011", "-"), ("\u2043", "-"),
    ("\u201c", '"'), ("\u201d", '"'), ("\u201e", '"'), ("\u201f", '"'),
    ("\u00ab", '"'), ("\u00bb", '"'), ("\u2033", '"'), ("\u301d", '"'), ("\u301e", '"'),
    ("\u2018", "'"), ("\u2019", "'"), ("\u201a", "'"), ("\u201b", "'"),
    ("\u2032", "'"), ("\u2039", '"'), ("\u203a", '"'), ("`", "'"),
    ("\u2026", "..."),
    ("\u00d7", "x"), ("\u00f7", "/"), ("\u2044", "/"), ("\u2215", "/"),
    ("\u2192", "-"), ("\u2190", "-"), ("\u2194", "-"), ("\u21d2", "-"), ("\u27f6", "-"),
    ("\u00b0C", " C"), ("\u00b0F", " F"),
    ("\u20ac", " EUR "), ("\u00a3", " GBP "), ("\u20bd", " RUB "), ("\u20b4", " UAH "), ("\u20b8", " KZT "),
    ("\u2116", "N"), ("\u00bd", "1/2"), ("\u00bc", "1/4"), ("\u00be", "3/4"),
    ("\u2122", ""), ("\u00ae", ""), ("\u00a9", "(c)"),
    ("\u00b2", "2"), ("\u00b3", "3"), ("\u00b9", "1"),
]
SPACES = {"\u00a0", "\u2000", "\u2001", "\u2002", "\u2003", "\u2004", "\u2005", "\u2006",
          "\u2007", "\u2008", "\u2009", "\u200a", "\u202f", "\u205f", "\u3000", "\t"}
INVISIBLE = {"\u200b", "\u200c", "\u200d", "\u2060", "\ufeff", "\u00ad", "\u200e", "\u200f",
             "\u202a", "\u202b", "\u202c", "\u202d", "\u202e", "\ufe0f", "\ufe0e"}
BULLETS = set("\u2022\u00b7\u25aa\u25ab\u25e6\u2023\u2043\u25cf\u25cb\u25a0\u25a1\u2219\u27a2\u2794\u25ba\u25b8\u2713\u2714\u2705")


def allowed_set(mode, markdown, keep):
    s = set(STRICT if mode == "strict" else CLASSIC)
    if markdown:
        s |= MARKDOWN
    s |= set(keep or "")
    return s


STRICT_FALLBACK = {"\u00bd": "0.5", "\u00bc": "0.25", "\u00be": "0.75", "\u00f7": ":", "\u2044": " ", "\u2215": " "}


def clean(text, allowed, stats, review=None):
    keep_tabs = "\t" in allowed
    out_lines = []
    for lineno, line in enumerate(text.split("\n"), 1):
        if review is not None:
            hits = sorted({c for c in line if c in MEANINGFUL and c not in allowed})
            if hits:
                review.append((lineno, "".join(hits), line.strip()[:80]))
        # bullet at line start -> "- "
        stripped = line.lstrip(" \t\u00a0")
        indent = line[: len(line) - len(stripped)]
        if stripped and stripped[0] in BULLETS:
            stats[stripped[0]] += 1
            stripped = "- " + stripped[1:].lstrip()
            line = indent + stripped
        for a, b in REPLACE:
            if a in line and a not in allowed:
                stats[a[0]] += line.count(a)
                if "/" in b and "/" not in allowed:
                    b = STRICT_FALLBACK.get(a, b.replace("/", " "))
                line = line.replace(a, b)
        buf = []
        for ch in line:
            if ch in allowed or ch == " " or ch == "\r":
                buf.append(ch)
            elif ch == "\t" and keep_tabs:
                buf.append(ch)
            elif ch in SPACES:
                stats[ch] += 1
                buf.append(" ")
            elif ch in INVISIBLE:
                stats[ch] += 1
            elif unicodedata.category(ch)[0] in ("L", "N", "M"):
                cat = unicodedata.category(ch)
                if cat in ("No",):  # circled/superscript digits etc.
                    stats[ch] += 1
                    d = unicodedata.digit(ch, None)
                    buf.append(str(d) if d is not None else "")
                else:
                    buf.append(ch)
            else:
                stats[ch] += 1
        line = "".join(buf)
        # tidy spaces left behind (inside the line only, keep indentation)
        body = line.lstrip(" ")
        ind = line[: len(line) - len(body)]
        while "  " in body:
            body = body.replace("  ", " ")
        for p in (" ,", " .", " !", " ?", " )", " :", " ;"):
            body = body.replace(p, p[1])
        body = body.replace("( ", "(")
        out_lines.append((ind + body).rstrip(" "))
    return "\n".join(out_lines)


def clean_docx(path, out, allowed, stats):
    import docx  # python-docx
    d = docx.Document(path)

    def paras(container):
        for p in container.paragraphs:
            yield p
        for t in getattr(container, "tables", []):
            for row in t.rows:
                for cell in row.cells:
                    yield from paras(cell)

    def all_paras():
        yield from paras(d)
        for s in d.sections:
            for part in (s.header, s.footer, s.first_page_header, s.first_page_footer):
                yield from paras(part)

    for p in all_paras():
        for r in p.runs:
            if r.text:
                r.text = clean(r.text, allowed, stats)
    d.save(out)


def report(stats, review):
    if review:
        print("Check these lines, a symbol with meaning was removed (rewrite in words if needed):", file=sys.stderr)
        for n, chars, txt in review:
            print(f"  line {n}: {chars}  | {txt}", file=sys.stderr)
    if not stats:
        print("No unusual symbols found.", file=sys.stderr)
        return
    print("Replaced or removed:", file=sys.stderr)
    for ch, n in stats.most_common():
        name = unicodedata.name(ch, "U+%04X" % ord(ch))
        shown = ch if ch.isprintable() and not ch.isspace() else " "
        print(f"  {n:5d}  {shown}  {name} (U+{ord(ch):04X})", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("-o", "--output")
    ap.add_argument("--mode", choices=["classic", "strict"], default="classic")
    ap.add_argument("--markdown", action="store_true", help="keep # * ` [ ] > | for Markdown")
    ap.add_argument("--keep", default="", help="extra characters to keep, e.g. '\u2116\u00b0\u20ac'")
    ap.add_argument("--report-only", action="store_true")
    a = ap.parse_args()

    allowed = allowed_set(a.mode, a.markdown or a.input.endswith(".md"), a.keep)
    stats = collections.Counter()
    review = []

    if a.input.lower().endswith(".docx"):
        out = a.output or a.input[:-5] + ".clean.docx"
        if a.report_only:
            import docx
            text = "\n".join(p.text for p in docx.Document(a.input).paragraphs)
            clean(text, allowed, stats, review)
        else:
            clean_docx(a.input, out, allowed, stats)
            print("Saved:", out, file=sys.stderr)
        report(stats, review)
        return

    text = sys.stdin.read() if a.input == "-" else open(a.input, encoding="utf-8-sig").read()
    result = clean(text, allowed, stats, review)
    if not a.report_only:
        if a.output:
            with open(a.output, "w", encoding="utf-8") as f:
                f.write(result)
            print("Saved:", a.output, file=sys.stderr)
        else:
            sys.stdout.write(result)
    report(stats, review)


if __name__ == "__main__":
    main()
