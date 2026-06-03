from __future__ import annotations

import html as _html

_SUPPORTED_LANGS = {"de", "en", "fr"}


def preferred_lang(accept_language: str) -> str:
    """Pick the best supported language from an Accept-Language header value."""
    for part in accept_language.split(","):
        tag = part.split(";")[0].strip()[:2].lower()
        if tag in _SUPPORTED_LANGS:
            return tag
    return "de"


# ── Localised strings ─────────────────────────────────────────────────────────

_READ_MORE: dict[str, str] = {
    "de": "Vollständigen Artikel lesen",
    "en": "Read full article",
    "fr": "Lire l'article complet",
}
_VIEW_EVENT: dict[str, str] = {
    "de": "Veranstaltungsdetails ansehen",
    "en": "View event details",
    "fr": "Voir les détails de l'événement",
}
_ERROR_TITLE: dict[str, str] = {
    "de": "Inhalt nicht verfügbar",
    "en": "Content unavailable",
    "fr": "Contenu indisponible",
}
_ERROR_BODY: dict[str, str] = {
    "de": (
        "Dieser Artikel konnte nicht gefunden werden. Bitte versuche es später erneut."
    ),
    "en": "This article could not be found. Please try again later.",
    "fr": "Cet article est introuvable. Veuillez réessayer plus tard.",
}

# ── Shared CSS ────────────────────────────────────────────────────────────────

_CSS = """\
:root {
  --bg:        #ffffff;
  --surface:   #f2f2f7;
  --text:      #1c1c1e;
  --secondary: #6e6e73;
  --accent:    #003d7a;
  --accent-fg: #ffffff;
  --link:      #0055a5;
  --border:    #d1d1d6;
  --warn-bg:   #fff3cd;
  --warn-text: #664d03;
  --warn-border:#ffc107;
  --radius:    12px;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg:        #000000;
    --surface:   #1c1c1e;
    --text:      #f2f2f7;
    --secondary: #8e8e93;
    --accent:    #0a84ff;
    --accent-fg: #ffffff;
    --link:      #409cff;
    --border:    #38383a;
    --warn-bg:   #2c2205;
    --warn-text: #ffd60a;
    --warn-border:#b38600;
  }
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html {
  color-scheme: light dark;
  -webkit-text-size-adjust: 100%;
}
body {
  font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
  font-size: clamp(15px, 4.2vw, 17px);
  line-height: 1.7;
  background: var(--bg);
  color: var(--text);
  padding-bottom: max(40px, env(safe-area-inset-bottom));
  -webkit-font-smoothing: antialiased;
}

/* ── Hero image ──────────────────────────────────────── */
.hero {
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  display: block;
}

/* ── Meta / title ────────────────────────────────────── */
.meta {
  font-size: 0.78em;
  color: var(--secondary);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin: 18px 16px 8px;
}
h1.title {
  font-size: clamp(18px, 5vw, 22px);
  font-weight: 700;
  line-height: 1.3;
  letter-spacing: -0.01em;
  margin: 0 16px 16px;
}

/* ── Full article body ───────────────────────────────── */
.article-body {
  padding: 0 16px;
}
.article-body p      { margin-bottom: 1.1em; }
.article-body h2     { font-size: 1.15em; font-weight: 700; margin: 1.6em 0 0.5em; letter-spacing: -0.01em; }
.article-body h3,
.article-body h4     { font-size: 1em; font-weight: 600; margin: 1.4em 0 0.4em; }
.article-body strong,
.article-body b      { font-weight: 600; }
.article-body em,
.article-body i      { font-style: italic; }
.article-body a      { color: var(--link); text-decoration: none; }
.article-body a:active { opacity: 0.7; }
.article-body ul,
.article-body ol     { margin: 0.6em 0 1em 1.4em; }
.article-body li     { margin-bottom: 0.3em; }
.article-body blockquote {
  border-left: 3px solid var(--accent);
  margin: 1em 0; padding: 0.4em 0 0.4em 1em;
  color: var(--secondary); font-style: italic;
}
.article-body img    { width: 100%; height: auto; border-radius: var(--radius); display: block; margin: 1.2em 0; }
.article-body figure { margin: 1.2em 0; }
.article-body figcaption { font-size: 0.82em; color: var(--secondary); margin-top: 0.4em; text-align: center; }

/* ── Fallback (RSS summary) ──────────────────────────── */
.fallback-notice {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin: 0 16px 16px;
  padding: 12px 14px;
  background: var(--warn-bg);
  border: 1px solid var(--warn-border);
  border-radius: var(--radius);
  font-size: 0.85em;
  color: var(--warn-text);
  line-height: 1.4;
}
.fallback-notice .icon { font-size: 1.2em; flex-shrink: 0; margin-top: 1px; }
.summary {
  font-size: 0.97em;
  color: var(--text);
  margin: 0 16px 20px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border);
}

/* ── Buttons ─────────────────────────────────────────── */
.read-more {
  display: block;
  margin: 28px 16px 0;
  padding: 14px 20px;
  background: var(--accent);
  color: var(--accent-fg);
  text-decoration: none;
  border-radius: var(--radius);
  text-align: center;
  font-weight: 600;
  font-size: 0.95em;
  letter-spacing: 0.01em;
  -webkit-tap-highlight-color: transparent;
}
.read-more:active { opacity: 0.85; }
.read-more.secondary {
  background: transparent;
  color: var(--accent);
  border: 1.5px solid var(--accent);
  margin-top: 16px;
}

/* ── Error screen ────────────────────────────────────── */
.error-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 70vh;
  padding: 40px 32px;
  text-align: center;
  gap: 16px;
}
.error-owl {
  font-size: 72px;
  line-height: 1;
  animation: droop 2.8s ease-in-out infinite;
}
@keyframes droop {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(6px); }
}
.error-title {
  font-size: 1.15em;
  font-weight: 700;
  color: var(--text);
}
.error-body {
  font-size: 0.92em;
  color: var(--secondary);
  max-width: 280px;
  line-height: 1.55;
}
"""

# ── Templates ─────────────────────────────────────────────────────────────────

_DETAIL_TEMPLATE = """\
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="color-scheme" content="light dark">
  <style>{css}</style>
</head>
<body>
  {hero}
  <p class="meta">{date}</p>
  <h1 class="title">{title}</h1>
  {body_section}
  {read_more}
</body>
</html>"""

_ERROR_TEMPLATE = """\
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="color-scheme" content="light dark">
  <style>{css}</style>
</head>
<body>
  <div class="error-screen">
    <div class="error-owl">🦉</div>
    <p class="error-title">{title}</p>
    <p class="error-body">{body}</p>
  </div>
</body>
</html>"""


# ── Public API ────────────────────────────────────────────────────────────────


def render_detail_html(
    item: dict[str, object],
    lang: str,
    *,
    is_event: bool,
    article_body: str | None = None,
) -> str:
    title = _html.escape(str(item.get("title") or ""))
    description = _html.escape(str(item.get("description") or ""))
    image_url = str(item.get("imageURL") or "")
    link = str(item.get("link") or "")
    date_str = _html.escape(
        str(item.get("happeningDate") or item.get("publishedDate") or "")
    )

    hero = (
        f'<img class="hero" src="{_html.escape(image_url)}" alt="" loading="eager">'
        if image_url
        else ""
    )

    btn_label = (_VIEW_EVENT if is_event else _READ_MORE).get(lang, "Read more")

    if article_body:
        # Happy path: full scraped article
        body_section = f'<div class="article-body">{article_body}</div>'
        read_more = (
            f'<a class="read-more secondary" href="{_html.escape(link)}">{btn_label}</a>'
            if link
            else ""
        )
    else:
        # Fallback: RSS summary + prominent CTA
        body_section = f'<p class="summary">{description}</p>'
        read_more = (
            f'<a class="read-more" href="{_html.escape(link)}">{btn_label}</a>'
            if link
            else ""
        )

    return _DETAIL_TEMPLATE.format(
        css=_CSS,
        hero=hero,
        date=date_str,
        title=title,
        body_section=body_section,
        read_more=read_more,
    )


def render_error_html(lang: str) -> str:
    return _ERROR_TEMPLATE.format(
        css=_CSS,
        title=_html.escape(_ERROR_TITLE.get(lang, _ERROR_TITLE["en"])),
        body=_html.escape(_ERROR_BODY.get(lang, _ERROR_BODY["en"])),
    )
