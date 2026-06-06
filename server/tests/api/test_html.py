from __future__ import annotations

from datetime import date

import pytest

from src.api._html import preferred_lang, render_detail_html, render_error_html
from src.core.enums import Language
from src.models.event import EventItem
from src.models.news import NewsItem


class TestPreferredLang:
    def test_exact_match(self) -> None:
        assert preferred_lang("de") == Language.DE
        assert preferred_lang("en") == Language.EN
        assert preferred_lang("fr") == Language.FR

    def test_region_subtag_stripped(self) -> None:
        assert preferred_lang("en-US") == Language.EN
        assert preferred_lang("de-AT") == Language.DE

    def test_quality_value_ignored(self) -> None:
        assert preferred_lang("en-US,en;q=0.9,de;q=0.8") == Language.EN

    def test_first_supported_wins(self) -> None:
        assert preferred_lang("fr,de") == Language.FR

    def test_unsupported_lang_falls_back_to_de(self) -> None:
        assert preferred_lang("zh,ja") == Language.DE

    def test_empty_header_falls_back_to_de(self) -> None:
        assert preferred_lang("") == Language.DE


_NEWS_ITEM = NewsItem(
    id=1,
    title="Test Article",
    published_date=date(2024, 1, 15),
    description="Short RSS summary.",
    link="https://example.com/article",
    image_url=None,
    categories=[],
)

_EVENT_ITEM = EventItem(
    id=2,
    title="Test Event",
    happening_date=date(2024, 6, 1),
    description="Event description.",
    link="https://example.com/event",
    image_url=None,
    categories=[],
)


class TestRenderDetailHtml:
    def test_rss_fallback_contains_title_and_summary(self) -> None:
        html = render_detail_html(_NEWS_ITEM, Language.DE, is_event=False)
        assert "Test Article" in html
        assert "Short RSS summary." in html

    def test_rss_fallback_contains_cta_link(self) -> None:
        html = render_detail_html(_NEWS_ITEM, Language.DE, is_event=False)
        assert "https://example.com/article" in html
        assert "read-more" in html

    def test_rss_fallback_has_no_article_body_div(self) -> None:
        html = render_detail_html(_NEWS_ITEM, Language.DE, is_event=False)
        assert 'class="article-body"' not in html

    def test_full_article_renders_body_content(self) -> None:
        html = render_detail_html(
            _NEWS_ITEM,
            Language.EN,
            is_event=False,
            article_body="<p>Full text here.</p>",
        )
        assert "Full text here." in html
        assert 'class="article-body"' in html

    def test_full_article_button_is_secondary(self) -> None:
        html = render_detail_html(
            _NEWS_ITEM, Language.EN, is_event=False, article_body="<p>content</p>"
        )
        assert "read-more secondary" in html

    def test_event_uses_event_cta_label(self) -> None:
        html = render_detail_html(_EVENT_ITEM, Language.DE, is_event=True)
        assert "Veranstaltungsdetails" in html

    def test_hero_image_rendered_when_present(self) -> None:
        item = NewsItem(
            id=3,
            title="With Image",
            published_date=None,
            description="desc",
            link="https://example.com",
            image_url="https://example.com/img.jpg",
            categories=[],
        )
        html = render_detail_html(item, Language.EN, is_event=False)
        assert "https://example.com/img.jpg" in html
        assert 'class="hero"' in html

    def test_no_hero_when_image_absent(self) -> None:
        html = render_detail_html(_NEWS_ITEM, Language.EN, is_event=False)
        assert 'class="hero"' not in html

    def test_title_is_html_escaped(self) -> None:
        item = NewsItem(
            id=4,
            title="<script>xss</script>",
            published_date=None,
            description="desc",
            link="https://example.com",
            image_url=None,
            categories=[],
        )
        html = render_detail_html(item, Language.EN, is_event=False)
        assert "<script>" not in html
        assert "&lt;script&gt;" in html


class TestRenderErrorHtml:
    def test_contains_owl_emoji(self) -> None:
        html = render_error_html(Language.EN)
        assert "🦉" in html

    @pytest.mark.parametrize(
        "lang, expected_title",
        [
            (Language.DE, "Inhalt nicht verfügbar"),
            (Language.EN, "Content unavailable"),
            (Language.FR, "Contenu indisponible"),
        ],
    )
    def test_all_supported_languages(self, lang: Language, expected_title: str) -> None:
        assert expected_title in render_error_html(lang)

    def test_unsupported_accept_language_falls_back_to_german_error(self) -> None:
        # preferred_lang converts any unknown header to Language.DE,
        # which then renders the German error page.
        lang = preferred_lang("zh,ja")
        html = render_error_html(lang)
        assert "Inhalt nicht verfügbar" in html
