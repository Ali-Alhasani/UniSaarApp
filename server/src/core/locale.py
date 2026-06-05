from __future__ import annotations

from src.core.enums import Language

# ── HTML detail page ──────────────────────────────────────────────────────────

READ_MORE: dict[Language, str] = {
    Language.DE: "Vollständigen Artikel lesen",
    Language.EN: "Read full article",
    Language.FR: "Lire l'article complet",
}
VIEW_EVENT: dict[Language, str] = {
    Language.DE: "Veranstaltungsdetails ansehen",
    Language.EN: "View event details",
    Language.FR: "Voir les détails de l'événement",
}
ERROR_TITLE: dict[Language, str] = {
    Language.DE: "Inhalt nicht verfügbar",
    Language.EN: "Content unavailable",
    Language.FR: "Contenu indisponible",
}
ERROR_BODY: dict[Language, str] = {
    Language.DE: (
        "Dieser Artikel konnte nicht gefunden werden. Bitte versuche es später erneut."
    ),
    Language.EN: "This article could not be found. Please try again later.",
    Language.FR: "Cet article est introuvable. Veuillez réessayer plus tard.",
}

# ── Plain-text API errors ─────────────────────────────────────────────────────

CACHE_NOT_READY: dict[Language, str] = {
    Language.DE: "Der Dienst wird gestartet. Bitte versuche es in einem Moment erneut.",
    Language.EN: "Service is starting up. Please try again in a moment.",
    Language.FR: (
        "Le service est en cours de démarrage. Veuillez réessayer dans un moment."
    ),
}
MEAL_NOT_FOUND: dict[Language, str] = {
    Language.DE: "Mahlzeitdetails nicht gefunden.",
    Language.EN: "Meal details not found.",
    Language.FR: "Détails du repas introuvables.",
}
DIRECTORY_QUERY_TOO_SHORT: dict[Language, str] = {
    Language.DE: "Die Suchanfrage muss mindestens 3 Zeichen lang sein.",
    Language.EN: "Search query must be at least 3 characters.",
    Language.FR: "La recherche doit contenir au moins 3 caractères.",
}
DIRECTORY_QUERY_TOO_BROAD: dict[Language, str] = {
    Language.DE: (
        "Die Suchanfrage hat zu viele Ergebnisse geliefert. Bitte sei spezifischer."
    ),
    Language.EN: "Search query returned too many results. Please be more specific.",
    Language.FR: (
        "La recherche a retourné trop de résultats. Veuillez être plus précis."
    ),
}
DIRECTORY_UNAVAILABLE: dict[Language, str] = {
    Language.DE: "Das Personalverzeichnis ist derzeit nicht verfügbar.",
    Language.EN: "The staff directory is not available right now.",
    Language.FR: "L'annuaire du personnel n'est pas disponible pour le moment.",
}
