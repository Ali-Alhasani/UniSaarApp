from __future__ import annotations

import html as _stdlib_html
from html.parser import HTMLParser as _StdParser

from selectolax.parser import HTMLParser

from src.services.base_scraper import BaseScraper, ScraperError

_UDS_BASE = "https://www.uni-saarland.de"

# CSS selectors tried in order to locate the article body.
# UdS runs TYPO3; these cover the known layouts.
_CONTENT_SELECTORS = [
    "article[itemtype*='Article'] .news-single-item",
    "article[itemtype*='Article'] .tx-news",
    "article[itemtype*='Article'] .ce-bodytext",
    ".news-single-item",
    ".tx-news-pi1",
    "article[itemtype*='Article']",
    "article",
]

# Elements removed before extraction — navigation, boilerplate, social share etc.
_STRIP_SELECTORS = [
    "script",
    "style",
    "nav",
    "footer",
    "aside",
    ".news-list-item__date",
    ".news-backlink-wrap",
    ".tx-news-pi1-pi1-backlink",
    "[class*='breadcrumb']",
    "[class*='social']",
    "[class*='share']",
    "[class*='related']",
    "[class*='teaser']",
    "[class*='pagination']",
    "header",
]

# Allowed HTML tags in the sanitised output.
_BLOCK_TAGS = {"p", "h2", "h3", "h4", "ul", "ol", "li", "blockquote", "figure", "figcaption"}
_INLINE_TAGS = {"strong", "em", "b", "i", "span"}
_VOID_TAGS = {"br", "img"}
_LINK_TAGS = {"a"}
_ALLOWED_TAGS = _BLOCK_TAGS | _INLINE_TAGS | _VOID_TAGS | _LINK_TAGS


class _Sanitizer(_StdParser):
    """Stream the raw container HTML through Python's stdlib parser and emit
    only allowed tags with safe attributes, making image/link URLs absolute."""

    def __init__(self, base_url: str) -> None:
        super().__init__(convert_charrefs=True)
        self._base = base_url
        self._out: list[str] = []
        self._stack: list[str | None] = []
        self._skip_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        attr = dict(attrs)

        if self._skip_depth:
            self._skip_depth += 1
            return

        if tag not in _ALLOWED_TAGS:
            self._skip_depth = 1
            return

        if tag == "img":
            src = attr.get("src", "") or ""
            if not src or src.startswith("data:"):
                self._skip_depth = 1
                return
            if src.startswith("/"):
                src = self._base + src
            alt = _stdlib_html.escape(attr.get("alt") or "")
            self._out.append(
                f'<img src="{_stdlib_html.escape(src)}" alt="{alt}" loading="lazy">'
            )
            self._stack.append(None)
            return

        if tag == "a":
            href = attr.get("href", "") or ""
            if href.startswith("javascript:") or href.startswith("data:"):
                self._skip_depth = 1
                return
            if href.startswith("/"):
                href = self._base + href
            self._out.append(f'<a href="{_stdlib_html.escape(href)}">')
            self._stack.append("a")
            return

        if tag == "br":
            self._out.append("<br>")
            self._stack.append(None)
            return

        self._out.append(f"<{tag}>")
        self._stack.append(tag)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if self._skip_depth:
            self._skip_depth -= 1
            return
        if self._stack:
            top = self._stack.pop()
            if top:
                self._out.append(f"</{top}>")

    def handle_data(self, data: str) -> None:
        if not self._skip_depth:
            self._out.append(_stdlib_html.escape(data))

    def result(self) -> str:
        return "".join(self._out)


def _extract(html: str) -> str | None:
    tree = HTMLParser(html)

    for sel in _STRIP_SELECTORS:
        for node in tree.css(sel):
            node.decompose()

    container = None
    for sel in _CONTENT_SELECTORS:
        found = tree.css_first(sel)
        if found and len(found.text(strip=True)) > 80:
            container = found
            break

    if container is None:
        return None

    raw = container.html or ""
    sanitizer = _Sanitizer(_UDS_BASE)
    sanitizer.feed(raw)
    cleaned = sanitizer.result().strip()
    return cleaned if len(cleaned) > 80 else None


class ArticleScraper(BaseScraper):
    """Fetches and extracts the full article body from a UdS article page."""

    def __init__(self) -> None:
        super().__init__()
        # Override with a short timeout — article scraping is best-effort;
        # we fall back to the RSS summary if the page is unreachable.
        import httpx
        from src.core.config import settings

        proxy = settings.proxy_url or None
        self._client = httpx.AsyncClient(
            proxy=proxy,
            timeout=10.0,
            follow_redirects=True,
        )

    async def fetch_article_body(self, url: str) -> str | None:
        try:
            html = await self.fetch(url)
        except ScraperError:
            return None
        try:
            return _extract(html)
        except Exception:
            return None
