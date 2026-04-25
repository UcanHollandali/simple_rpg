# Usage (Windows): py -3 Tools/validate_assets.py
# Usage (macOS/Linux): python3 Tools/validate_assets.py

from __future__ import annotations

import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path


REQUIRED_COLUMNS = (
    "asset_id",
    "area",
    "status",
    "source_tool",
    "source_origin",
    "license",
    "ai_used",
    "commercial_status",
    "master_path",
    "runtime_path",
    "replace_before_release",
    "last_reviewed_at",
    "notes",
)

REQUIRED_NONEMPTY_FIELDS = (
    "asset_id",
    "area",
    "status",
    "source_origin",
    "license",
    "ai_used",
    "commercial_status",
    "replace_before_release",
)

ALLOWED_STATUS_VALUES = {
    "placeholder",
    "candidate",
    "approved_for_prototype",
    "replace_before_release",
}
ALLOWED_COMMERCIAL_STATUS_VALUES = {
    "commercial_use_allowed",
    "commercial_use_needs_review",
    "commercial_use_not_allowed",
}

BOOLEANISH_VALUES = {"yes", "no", "true", "false"}
ASSET_ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
REVIEW_DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")
RUNTIME_TRACKED_EXTENSIONS = {
    ".svg",
    ".png",
    ".jpg",
    ".jpeg",
    ".ogg",
    ".wav",
    ".mp3",
    ".ttf",
    ".otf",
    ".woff",
    ".woff2",
}
SOURCE_ART_ROOT_PREFIX = "SourceArt/"
SOURCE_ART_GENERATED_PREFIX = "SourceArt/Generated/"
ACTIVE_SOURCE_PREVIEW_NAME_FRAGMENT = "_preview."


@dataclass
class ValidationIssue:
    path: str
    issue_type: str
    message: str


def main(argv: list[str]) -> int:
    if len(argv) > 1:
        print("Usage (Windows): py -3 Tools/validate_assets.py", file=sys.stderr)
        print("Usage (macOS/Linux): python3 Tools/validate_assets.py", file=sys.stderr)
        return 2

    repo_root = Path(__file__).resolve().parent.parent
    manifest_path = repo_root / "AssetManifest" / "asset_manifest.csv"

    errors, warnings = validate_manifest(repo_root, manifest_path)
    warnings.extend(validate_active_source_lane_clutter(repo_root))

    if errors:
        for error in errors:
            print(f"{error.path} | {error.issue_type} | {error.message}")
        return 1

    for warning in warnings:
        print(f"{warning.path} | warning:{warning.issue_type} | {warning.message}")

    print("Asset manifest valid.")
    return 0


def validate_manifest(repo_root: Path, manifest_path: Path) -> tuple[list[ValidationIssue], list[ValidationIssue]]:
    errors: list[ValidationIssue] = []
    warnings: list[ValidationIssue] = []
    manifest_rows: list[tuple[int, dict[str, str]]] = []
    seen_runtime_paths: dict[str, int] = {}
    referenced_runtime_paths: set[str] = set()

    if not manifest_path.exists():
        errors.append(
            ValidationIssue(str(manifest_path), "missing_manifest", "asset_manifest.csv was not found.")
        )
        return errors, warnings

    try:
        with manifest_path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if reader.fieldnames is None:
                errors.append(
                    ValidationIssue(str(manifest_path), "missing_header", "Asset manifest header row is missing.")
                )
                return errors, warnings

            header = tuple(reader.fieldnames)
            missing_columns = [column for column in REQUIRED_COLUMNS if column not in header]
            if missing_columns:
                errors.append(
                    ValidationIssue(
                        str(manifest_path),
                        "missing_required_columns",
                        "Missing required manifest columns: %s." % ", ".join(missing_columns),
                    )
                )
                return errors, warnings

            seen_asset_ids: dict[str, int] = {}
            nonempty_row_count = 0
            for row_number, row in enumerate(reader, start=2):
                has_values = validate_row(
                    repo_root,
                    manifest_path,
                    row_number,
                    row,
                    seen_asset_ids,
                    seen_runtime_paths,
                    referenced_runtime_paths,
                    manifest_rows,
                    errors,
                    warnings,
                )
                if has_values:
                    nonempty_row_count += 1

            if nonempty_row_count == 0:
                errors.append(
                    ValidationIssue(
                        str(manifest_path),
                        "missing_manifest_entries",
                        "asset_manifest.csv must contain at least one real manifest entry.",
                    )
                )
            else:
                validate_manifest_policy_consistency(manifest_path, manifest_rows, errors, warnings)
                validate_runtime_asset_coverage(repo_root, manifest_path, referenced_runtime_paths, errors)
                validate_svg_git_rule(repo_root, errors)
    except OSError as exc:
        errors.append(
            ValidationIssue(str(manifest_path), "manifest_read_error", str(exc))
        )

    return errors, warnings


def validate_row(
    repo_root: Path,
    manifest_path: Path,
    row_number: int,
    row: dict[str, str | None],
    seen_asset_ids: dict[str, int],
    seen_runtime_paths: dict[str, int],
    referenced_runtime_paths: set[str],
    manifest_rows: list[tuple[int, dict[str, str]]],
    errors: list[ValidationIssue],
    warnings: list[ValidationIssue],
) -> bool:
    normalized_row = {key: (value or "").strip() for key, value in row.items()}

    if not any(normalized_row.values()):
        return False

    location = f"{manifest_path}:{row_number}"

    for field in REQUIRED_NONEMPTY_FIELDS:
        if not normalized_row.get(field, ""):
            errors.append(
                ValidationIssue(
                    location,
                    "missing_required_value",
                    f"Field '{field}' must be non-empty.",
                )
            )

    asset_id = normalized_row.get("asset_id", "")
    if asset_id:
        if not ASSET_ID_PATTERN.match(asset_id):
            errors.append(
                ValidationIssue(
                    location,
                    "invalid_asset_id",
                    f"asset_id '{asset_id}' must match ^[a-z][a-z0-9_]*$.",
                )
            )
        previous_row = seen_asset_ids.get(asset_id)
        if previous_row is not None:
            errors.append(
                ValidationIssue(
                    location,
                    "duplicate_asset_id",
                    f"asset_id '{asset_id}' is already used on row {previous_row}.",
                )
            )
        else:
            seen_asset_ids[asset_id] = row_number

    status = normalized_row.get("status", "")
    if status and status not in ALLOWED_STATUS_VALUES:
        errors.append(
            ValidationIssue(
                location,
                "invalid_status",
                "status '%s' must be one of: %s."
                % (status, ", ".join(sorted(ALLOWED_STATUS_VALUES))),
            )
        )

    for field in ("ai_used", "replace_before_release"):
        value = normalized_row.get(field, "").lower()
        if value and value not in BOOLEANISH_VALUES:
            errors.append(
                ValidationIssue(
                    location,
                    "invalid_booleanish_value",
                    f"Field '{field}' must use yes/no or true/false.",
                )
            )

    commercial_status = normalized_row.get("commercial_status", "")
    if commercial_status and commercial_status not in ALLOWED_COMMERCIAL_STATUS_VALUES:
        errors.append(
            ValidationIssue(
                location,
                "invalid_commercial_status",
                "commercial_status '%s' must be one of: %s."
                % (commercial_status, ", ".join(sorted(ALLOWED_COMMERCIAL_STATUS_VALUES))),
            )
        )

    review_date = normalized_row.get("last_reviewed_at", "")
    if review_date and not REVIEW_DATE_PATTERN.match(review_date):
        warnings.append(
            ValidationIssue(
                location,
                "invalid_review_date_format",
                "last_reviewed_at should use YYYY-MM-DD when present.",
            )
        )

    runtime_path = normalized_row.get("runtime_path", "")
    if runtime_path:
        normalized_runtime_path = runtime_path.replace("\\", "/")
        previous_row = seen_runtime_paths.get(normalized_runtime_path)
        if previous_row is not None:
            errors.append(
                ValidationIssue(
                    location,
                    "duplicate_runtime_path",
                    f"runtime_path '{runtime_path}' is already used on row {previous_row}.",
                )
            )
        else:
            seen_runtime_paths[normalized_runtime_path] = row_number
        referenced_runtime_paths.add(normalized_runtime_path)
        validate_runtime_path(repo_root, location, runtime_path, errors)

    master_path = normalized_row.get("master_path", "")
    if master_path:
        validate_master_path(repo_root, location, master_path, errors, warnings)

    manifest_rows.append((row_number, normalized_row))

    return True


def validate_runtime_path(
    repo_root: Path,
    location: str,
    runtime_path: str,
    errors: list[ValidationIssue],
) -> None:
    normalized = runtime_path.replace("\\", "/")

    if not normalized.startswith("Assets/"):
        errors.append(
            ValidationIssue(
                location,
                "invalid_runtime_path_root",
                "runtime_path must point inside Assets/ when present.",
            )
        )
        return

    full_path = repo_root / Path(normalized)
    if not full_path.exists():
        errors.append(
            ValidationIssue(
                location,
                "missing_runtime_asset",
                f"runtime_path '{runtime_path}' does not exist.",
            )
        )


def validate_master_path(
    repo_root: Path,
    location: str,
    master_path: str,
    errors: list[ValidationIssue],
    warnings: list[ValidationIssue],
) -> None:
    normalized = master_path.replace("\\", "/")
    if not normalized.startswith(SOURCE_ART_ROOT_PREFIX):
        errors.append(
            ValidationIssue(
                location,
                "invalid_master_path_root",
                "master_path should point inside SourceArt/ for provenance truth.",
            )
        )
        return

    full_path = repo_root / Path(normalized)
    if full_path.exists():
        return

    warnings.append(
        ValidationIssue(
            location,
            "missing_master_path",
            f"master_path '{master_path}' does not exist.",
        )
    )


def validate_active_source_lane_clutter(repo_root: Path) -> list[ValidationIssue]:
    warnings: list[ValidationIssue] = []
    edited_root = repo_root / "SourceArt" / "Edited"
    if not edited_root.exists():
        return warnings

    for path in sorted(edited_root.rglob("*")):
        if not path.is_file():
            continue
        name = path.name.lower()
        if ACTIVE_SOURCE_PREVIEW_NAME_FRAGMENT not in name:
            continue
        warnings.append(
				ValidationIssue(
					str(path.relative_to(repo_root).as_posix()),
					"active_source_preview_clutter",
					"Preview-sheet clutter should not stay in SourceArt/Edited; keep temporary review previews in ignored export output and leave only active masters in SourceArt/Edited.",
				)
			)

    return warnings


def validate_manifest_policy_consistency(
    manifest_path: Path,
    manifest_rows: list[tuple[int, dict[str, str]]],
    errors: list[ValidationIssue],
    warnings: list[ValidationIssue],
) -> None:
    for row_number, row in manifest_rows:
        location = f"{manifest_path}:{row_number}"
        status = row.get("status", "")
        replace_before_release = row.get("replace_before_release", "").lower()
        commercial_status = row.get("commercial_status", "")
        runtime_path = row.get("runtime_path", "")
        master_path = row.get("master_path", "")
        ai_used = row.get("ai_used", "").lower()

        if status == "placeholder" and replace_before_release not in {"yes", "true"}:
            errors.append(
                ValidationIssue(
                    location,
                    "placeholder_must_be_replaceable",
                    "Placeholder runtime assets must use replace_before_release=yes.",
                )
            )

        if status == "candidate" and replace_before_release not in {"yes", "true"}:
            errors.append(
                ValidationIssue(
                    location,
                    "candidate_must_be_replaceable",
                    "Candidate runtime assets must use replace_before_release=yes.",
                )
            )

        if status == "replace_before_release" and replace_before_release not in {"yes", "true"}:
            errors.append(
                ValidationIssue(
                    location,
                    "replace_status_must_be_replaceable",
                    "replace_before_release status must use replace_before_release=yes.",
                )
            )

        if commercial_status == "commercial_use_not_allowed" and replace_before_release not in {"yes", "true"}:
            errors.append(
                ValidationIssue(
                    location,
                    "commercially_blocked_asset_must_be_flagged",
                    "commercial_use_not_allowed assets must use replace_before_release=yes.",
                )
            )

        if runtime_path and not master_path:
            warnings.append(
                ValidationIssue(
                    location,
                    "runtime_asset_missing_master_path",
                    "Runtime-tracked assets should also record a master_path for provenance review.",
                )
            )

        normalized_master_path = master_path.replace("\\", "/")
        source_tool = row.get("source_tool", "")

        if status == "approved_for_prototype" and normalized_master_path.startswith(SOURCE_ART_GENERATED_PREFIX):
            errors.append(
                ValidationIssue(
                    location,
                    "approved_asset_still_on_generated_source",
                    "approved_for_prototype assets must not point at SourceArt/Generated/; move the approved master into an active reviewed lane first.",
                )
            )

        if source_tool == "repo_authored_reviewed_master" and normalized_master_path.startswith(SOURCE_ART_GENERATED_PREFIX):
            errors.append(
                ValidationIssue(
                    location,
                    "reviewed_master_points_to_generated_lane",
                    "repo_authored_reviewed_master should not point into SourceArt/Generated/; keep reviewed masters in a cleaned active lane.",
                )
            )

        if ai_used in {"yes", "true"} and commercial_status == "commercial_use_allowed" and replace_before_release in {"no", "false"}:
            warnings.append(
                ValidationIssue(
                    location,
                    "ai_asset_release_flag",
                    "AI-assisted assets marked commercially allowed should still be reviewed carefully before release.",
                )
            )


def validate_runtime_asset_coverage(
    repo_root: Path,
    manifest_path: Path,
    referenced_runtime_paths: set[str],
    errors: list[ValidationIssue],
) -> None:
    assets_root = repo_root / "Assets"
    if not assets_root.exists():
        return

    for asset_path in sorted(assets_root.rglob("*")):
        if not asset_path.is_file():
            continue
        if asset_path.suffix.lower() not in RUNTIME_TRACKED_EXTENSIONS:
            continue

        normalized_runtime_path = asset_path.relative_to(repo_root).as_posix()
        if normalized_runtime_path not in referenced_runtime_paths:
            errors.append(
                ValidationIssue(
                    str(manifest_path),
                    "untracked_runtime_asset",
                    f"Runtime asset '{normalized_runtime_path}' is not tracked in asset_manifest.csv.",
                )
            )


def validate_svg_git_rule(repo_root: Path, errors: list[ValidationIssue]) -> None:
    gitattributes_path = repo_root / ".gitattributes"
    if not gitattributes_path.exists():
        errors.append(
            ValidationIssue(str(gitattributes_path), "missing_gitattributes", ".gitattributes was not found.")
        )
        return

    try:
        lines = gitattributes_path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        errors.append(
            ValidationIssue(str(gitattributes_path), "gitattributes_read_error", str(exc))
        )
        return

    svg_rule_found = False
    for raw_line in lines:
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if not line.startswith("*.svg"):
            continue
        if "binary" in line:
            errors.append(
                ValidationIssue(
                    str(gitattributes_path),
                    "svg_marked_binary",
                    "*.svg must stay text-reviewable; do not mark it as binary.",
                )
            )
            return
        if "text" in line:
            svg_rule_found = True

    if not svg_rule_found:
        errors.append(
            ValidationIssue(
                str(gitattributes_path),
                "missing_svg_text_rule",
                ".gitattributes must keep *.svg as text-reviewable.",
            )
        )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
