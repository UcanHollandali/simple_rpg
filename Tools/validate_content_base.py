from __future__ import annotations

import json
from pathlib import Path
from re import Pattern


class ValidationIssue:
    def __init__(self, path: Path, error_type: str, message: str) -> None:
        self.path = str(path)
        self.error_type = error_type
        self.message = message


class ValidationError(ValidationIssue):
    pass


class ValidationWarning(ValidationIssue):
    pass


def iter_content_files(content_root: Path) -> list[Path]:
    return sorted(content_root.rglob("*.json"))


def load_json(json_path: Path, errors: list[ValidationIssue]) -> dict | list | None:
    try:
        with json_path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        errors.append(
            ValidationError(
                json_path,
                "invalid_json",
                f"JSON parse error at line {exc.lineno}, column {exc.colno}: {exc.msg}",
            )
        )
    except OSError as exc:
        errors.append(ValidationError(json_path, "file_read_error", str(exc)))
    return None


def validate_definition_id(
    json_path: Path,
    definition_id: str,
    seen_definition_ids: dict[str, Path],
    errors: list[ValidationIssue],
    definition_id_pattern: Pattern[str],
) -> None:
    if not definition_id_pattern.match(definition_id):
        errors.append(
            ValidationError(
                json_path,
                "invalid_definition_id_format",
                f"definition_id '{definition_id}' must match ^[a-z][a-z0-9_]*$.",
            )
        )

    previous_path = seen_definition_ids.get(definition_id)
    if previous_path is not None:
        errors.append(
            ValidationError(
                json_path,
                "duplicate_definition_id",
                f"definition_id '{definition_id}' is already used by {previous_path}.",
            )
        )
        return

    seen_definition_ids[definition_id] = json_path


def validate_family(
    json_path: Path,
    family: str,
    content_root: Path,
    errors: list[ValidationIssue],
    supported_families: set[str],
) -> None:
    if family not in supported_families:
        errors.append(
            ValidationError(
                json_path,
                "invalid_family",
                f"family '{family}' is not in the supported family list.",
            )
        )
        return

    try:
        relative_parts = json_path.relative_to(content_root).parts
    except ValueError:
        errors.append(
            ValidationError(json_path, "path_error", "File is not inside ContentDefinitions root.")
        )
        return

    if not relative_parts:
        errors.append(
            ValidationError(json_path, "path_error", "Could not determine content family folder from path.")
        )
        return

    folder_name = relative_parts[0]
    if folder_name != family:
        errors.append(
            ValidationError(
                json_path,
                "family_folder_mismatch",
                f"Path folder '{folder_name}' does not match family '{family}'.",
            )
        )


def validate_authoring_order(
    json_path: Path,
    family: str,
    data: dict,
    seen_authoring_orders: dict[str, dict[int, Path]],
    errors: list[ValidationIssue],
    ordered_authoring_families: set[str],
    ordering_field_name: str,
) -> None:
    if family not in ordered_authoring_families:
        if ordering_field_name in data:
            errors.append(
                ValidationError(
                    json_path,
                    "unsupported_authoring_order",
                    f"{family} definitions must not use top-level field '{ordering_field_name}' in the current runtime-backed slice.",
                )
            )
        return

    authoring_order = data.get(ordering_field_name)
    if isinstance(authoring_order, bool) or not isinstance(authoring_order, int) or authoring_order <= 0:
        errors.append(
            ValidationError(
                json_path,
                "invalid_authoring_order",
                f"{family} definitions must use a positive integer top-level field '{ordering_field_name}'.",
            )
        )
        return

    family_orders = seen_authoring_orders.setdefault(family, {})
    previous_path = family_orders.get(authoring_order)
    if previous_path is not None:
        errors.append(
            ValidationError(
                json_path,
                "duplicate_authoring_order",
                f"{family} '{ordering_field_name}' value {authoring_order} is already used by {previous_path}.",
            )
        )
        return

    family_orders[authoring_order] = json_path
