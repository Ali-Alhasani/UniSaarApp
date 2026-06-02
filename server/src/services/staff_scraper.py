from __future__ import annotations

import re
import urllib.parse

from selectolax.parser import HTMLParser, Node

from src.core.constants import STAFF_DETAIL_URL, STAFF_SEARCH_URL
from src.models.staff import StaffDetails, StaffFunction, StaffItem, StaffList
from src.services.base_scraper import BaseScraper

_TOO_VAGUE_MESSAGES = (
    "Bitte geben Sie mehr Suchbegriffe ein",
    "Bitte spezifizieren Sie Ihre Suchanfrage",
)


class StaffSearchTooVagueError(Exception):
    pass


class StaffScraper(BaseScraper):
    async def search(self, query: str) -> StaffList:
        url = STAFF_SEARCH_URL.format(query=urllib.parse.quote(query))
        html = await self.fetch(url)
        items = self._parse_search_results(html)
        return StaffList(item_count=len(items), has_next_page=False, results=items)

    async def fetch_details(self, pid: int) -> StaffDetails:
        url = STAFF_DETAIL_URL.format(pid=pid)
        html = await self.fetch(url)
        return self._parse_details(html)

    @staticmethod
    def _parse_search_results(html: str) -> list[StaffItem]:
        tree = HTMLParser(html)

        for h1 in tree.css("h1"):
            text = h1.text().strip()
            if any(msg in text for msg in _TOO_VAGUE_MESSAGES):
                raise StaffSearchTooVagueError(text)

        items: list[StaffItem] = []
        for entry in tree.css("div.erg_list_entry"):
            label = entry.css_first("div.erg_list_label")
            if label is None or label.text().strip() != "Name:":
                continue
            link = entry.css_first("a.regular")
            if link is None:
                continue
            href = link.attributes.get("href") or ""
            m = re.search(r"personal\.pid=(\d+)", href)
            if m is None:
                continue
            pid = int(m.group(1))

            parts = [p.strip() for p in link.text().splitlines() if p.strip()]
            if len(parts) >= 3:
                title, name = parts[0], f"{parts[1]} {parts[2]}"
            elif len(parts) == 2:
                title, name = "", f"{parts[0]} {parts[1]}"
            elif len(parts) == 1:
                title, name = "", parts[0]
            else:
                continue

            items.append(StaffItem(name=name, title=title, pid=pid))

        return items

    @staticmethod
    def _table_value(table: Node, keyword: str) -> str:
        for th in table.css("th"):
            th_id = th.attributes.get("id", "")
            if not th_id:
                continue
            if keyword.lower() in th.text().strip().lower():
                td = table.css_first(f'td[headers="{th_id}"]')
                if td is not None:
                    return td.text().strip().replace("\xa0", " ")
        return ""

    @staticmethod
    def _parse_functions(func_table: Node) -> list[StaffFunction]:
        functions: list[StaffFunction] = []
        for row in func_table.css("tr"):
            dept_td = row.css_first('td[headers="basic_1"]')
            if dept_td is None:
                continue
            func_td = row.css_first('td[headers="basic_2"]')
            start_td = row.css_first('td[headers="basic_3"]')
            end_td = row.css_first('td[headers="basic_4"]')

            dept = dept_td.text().strip().replace("\xa0", " ") or None
            func = func_td.text().strip().replace("\xa0", " ") if func_td else None
            start = start_td.text().strip().replace("\xa0", " ") if start_td else None
            end = end_td.text().strip().replace("\xa0", " ") if end_td else None

            functions.append(
                StaffFunction(
                    f_department=dept or None,
                    f_function=func or None,
                    f_start=start or None,
                    f_end=end or None,
                )
            )
        return functions

    def _parse_details(self, html: str) -> StaffDetails:
        tree = HTMLParser(html)

        basic = tree.css_first('table[summary="Grunddaten zur Veranstaltung"]')
        addr = tree.css_first('table[summary="Angaben zur Dienstadresse"]')
        func_table = tree.css_first('table[summary="Funktionen"]')

        def bv(keyword: str) -> str:
            return self._table_value(basic, keyword) if basic else ""

        def av(keyword: str) -> str:
            return self._table_value(addr, keyword) if addr else ""

        title = bv("Akad. Grad") or bv("Titel")
        functions = self._parse_functions(func_table) if func_table else []

        return StaffDetails(
            first_name=bv("Vorname"),
            last_name=bv("Nachname"),
            title=title,
            gender=bv("Geschlecht"),
            office_hour=bv("Sprechzeit"),
            remark=bv("Bemerkung"),
            office=av("Dienstzimmer"),
            building=av("Gebäude"),
            street=av("Straße"),
            postal_code=av("PLZ"),
            city=av("Ort"),
            phone=av("Telefon"),
            fax=av("Fax"),
            mail=av("E-Mail"),
            webpage=av("Hyperlink"),
            image_link=None,
            functions=functions,
        )
