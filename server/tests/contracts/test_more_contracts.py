"""Contract tests — assert serialized keys match iOS Codable field names."""

from src.models.more import MoreLink, MoreLinksResponse


class TestMoreLinkContract:
    def test_ios_keys(self) -> None:
        data = MoreLink(name="Welcome Centre", link="https://example.com").model_dump(
            by_alias=True
        )
        assert "name" in data
        assert "link" in data

    def test_no_extra_keys(self) -> None:
        data = MoreLink(name="AStA", link="https://asta.uni-saarland.de/").model_dump(
            by_alias=True
        )
        assert set(data.keys()) == {"name", "link"}


class TestMoreLinksResponseContract:
    def test_ios_keys(self) -> None:
        resp = MoreLinksResponse(
            links_last_changed="2020-01-20 17:42:14",
            language="de",
            links=[
                MoreLink(
                    name="Welcome Centre",
                    link="https://www.uni-saarland.de/en/global/welcome-center.html",
                ),
            ],
        )
        data = resp.model_dump(by_alias=True)
        assert "linksLastChanged" in data
        assert "language" in data
        assert "links" in data
        assert "links_last_changed" not in data

    def test_links_contain_ios_keys(self) -> None:
        resp = MoreLinksResponse(
            links_last_changed="2020-01-20",
            language="en",
            links=[MoreLink(name="AStA", link="https://asta.uni-saarland.de/en/")],
        )
        data = resp.model_dump(by_alias=True)
        link = data["links"][0]
        assert "name" in link
        assert "link" in link
