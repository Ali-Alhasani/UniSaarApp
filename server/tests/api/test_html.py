from __future__ import annotations

from src.api._html import preferred_lang, render_detail_html, render_error_html


class TestPreferredLang:
    def test_exact_match(self) -> None:
        assert preferred_lang("de") == "de"
        assert preferred_lang("en") == "en"
        assert preferred_lang("fr") == "fr"

    def test_region_subtag_stripped(self) -> None:
        assert preferred_lang("en-US") == "en"
        assert preferred_lang("de-AT") == "de"

    def test_quality_value_ignored(self) -> None:
        assert preferred_lang("en-US,en;q=0.9,de;q=0.8") == "en"

    def test_first_supported_wins(self) -> None:
        assert preferred_lang("fr,de") == "fr"

    def test_unsupported_lang_falls_back_to_de(self) -> None:
        assert preferred_lang("zh,ja") == "de"

    def test_empty_header_falls_back_to_de(self) -> None:
        assert preferred_lang("") == "de"


_ITEM: dict[str, object] = {
    "id": 1,
    "title": "Test Article",
    "publishedDate": "2024-01-15",
    "happeningDate": None,
    "description": "Short RSS summary.",
    "link": "https://example.com/article",
    "imageURL": None,
}


class TestRenderDetailHtml:
    def test_rss_fallback_contains_title_and_summary(self) -> None:
        html = render_detail_html(_ITEM, "de", is_event=False)
        assert "Test Article" in html
        assert "Short RSS summary." in html

    def test_rss_fallback_contains_cta_link(self) -> None:
        html = render_detail_html(_ITEM, "de", is_event=False)
        assert "https://example.com/article" in html
        assert "read-more" in html

    def test_rss_fallback_has_no_article_body_div(self) -> None:
        html = render_detail_html(_ITEM, "de", is_event=False)
        assert 'class="article-body"' not in html

    def test_full_article_renders_body_content(self) -> None:
        html = render_detail_html(
            _ITEM, "en", is_event=False, article_body="<p>Full text here.</p>"
        )
        assert "Full text here." in html
        assert 'class="article-body"' in html

    def test_full_article_button_is_secondary(self) -> None:
        html = render_detail_html(
            _ITEM, "en", is_event=False, article_body="<p>content</p>"
        )
        assert "read-more secondary" in html

    def test_event_uses_event_cta_label(self) -> None:
        item = {**_ITEM, "happeningDate": "2024-06-01"}
        html = render_detail_html(item, "de", is_event=True)
        assert "Veranstaltungsdetails" in html

    def test_hero_image_rendered_when_present(self) -> None:
        item = {**_ITEM, "imageURL": "https://example.com/img.jpg"}
        html = render_detail_html(item, "en", is_event=False)
        assert "https://example.com/img.jpg" in html
        assert 'class="hero"' in html

    def test_no_hero_when_image_absent(self) -> None:
        html = render_detail_html(_ITEM, "en", is_event=False)
        assert 'class="hero"' not in html

    def test_title_is_html_escaped(self) -> None:
        item = {**_ITEM, "title": "<script>xss</script>"}
        html = render_detail_html(item, "en", is_event=False)
        assert "<script>" not in html
        assert "&lt;script&gt;" in html


class TestRenderErrorHtml:
    def test_contains_owl_emoji(self) -> None:
        html = render_error_html("en")
        assert "🦉" in html

    def test_english_error_text(self) -> None:
        html = render_error_html("en")
        assert "Content unavailable" in html

    def test_german_error_text(self) -> None:
        html = render_error_html("de")
        assert "Inhalt nicht verfügbar" in html

    def test_french_error_text(self) -> None:
        html = render_error_html("fr")
        assert "Contenu indisponible" in html

    def test_unknown_lang_falls_back_to_english(self) -> None:
        html = render_error_html("xx")
        assert "Content unavailable" in html
