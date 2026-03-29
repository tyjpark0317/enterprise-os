#!/usr/bin/env python3
"""C-Suite role-specific current-state.md section extractor.

Extracts only the sections relevant to each executive role and removes
completed items to conserve context budget.

Usage: python3 csuite-context-extract.py <role> <current-state-path>
Output: Filtered content to stdout
"""

import re
import sys


# Role-to-section mapping — customize for your organization
ROLE_SECTIONS = {
    "ceo": [
        "BLUF",
        "Strategic Priorities",
        "Key Decisions",
        "Key Metrics",
        "Standing Orders",
    ],
    "cto": [
        "BLUF",
        "Strategic Priorities",
        "Next TODO",
        "Action Items Tracker",
        "Key Metrics",
        "Routine Audit Status",
        "Standing Orders",
        "Reference Documents",
    ],
    "cfo": [
        "BLUF",
        "Strategic Priorities",
        "Key Decisions",
        "Key Metrics",
        "Standing Orders",
    ],
    "cmo": [
        "BLUF",
        "Strategic Priorities",
        "Key Decisions",
        "Key Metrics",
        "Standing Orders",
    ],
    "cpo": [
        "BLUF",
        "Strategic Priorities",
        "Next TODO",
        "Key Decisions",
        "Key Metrics",
        "Standing Orders",
    ],
    "clo": [
        "BLUF",
        "Strategic Priorities",
        "Key Decisions",
        "Standing Orders",
    ],
    "coo": [
        "BLUF",
        "Strategic Priorities",
        "Key Metrics",
        "Routine Audit Status",
        "Standing Orders",
    ],
    "chro": [
        "BLUF",
        "Key Metrics",
        "Standing Orders",
    ],
    "actuary": [
        "BLUF",
        "Key Metrics",
    ],
}

# Sections where completed items should be filtered out
SECTIONS_TO_FILTER_COMPLETED = {"Next TODO", "Action Items Tracker"}


def parse_sections(content: str) -> dict[str, str]:
    """Split current-state.md into sections by ## headers."""
    sections = {}
    current_name = None
    current_lines: list[str] = []

    for line in content.split("\n"):
        match = re.match(r"^## (.+)$", line)
        if match:
            if current_name is not None:
                sections[current_name] = "\n".join(current_lines).rstrip()
            current_name = match.group(1).strip()
            current_lines = [line]
        else:
            current_lines.append(line)

    if current_name is not None:
        sections[current_name] = "\n".join(current_lines).rstrip()

    return sections


def is_completed_row(line: str) -> bool:
    """Determine if a table row represents a completed item."""
    if not line.startswith("|"):
        return False
    # Strikethrough + check mark pattern
    if "~~" in line and "\u2705" in line:
        return True
    # Status cell with completion indicators
    if re.search(r"\|\s*\u2705\s*(done|completed|merged|finished)\s*\|", line, re.IGNORECASE):
        return True
    return False


def filter_completed(section_content: str) -> str:
    """Remove completed item rows from a section."""
    lines = section_content.split("\n")
    filtered = []
    for line in lines:
        if is_completed_row(line):
            continue
        filtered.append(line)
    return "\n".join(filtered)


def extract_for_role(content: str, role: str) -> str:
    """Extract role-relevant sections and filter completed items."""
    sections = parse_sections(content)
    needed = ROLE_SECTIONS.get(role, ROLE_SECTIONS["ceo"])

    # Header (content before first ## section)
    header_match = re.match(r"^(.*?)(?=\n## )", content, re.DOTALL)
    parts = []
    if header_match:
        header = header_match.group(1).strip()
        if header:
            parts.append(header)

    for section_name in needed:
        # Partial matching for flexibility
        matched_key = None
        for key in sections:
            if section_name in key:
                matched_key = key
                break

        if matched_key is None:
            continue

        section_text = sections[matched_key]

        # Filter completed items from designated sections
        if section_name in SECTIONS_TO_FILTER_COMPLETED:
            section_text = filter_completed(section_text)

        parts.append(section_text)

    result = "\n\n---\n\n".join(parts)

    return result


def main():
    if len(sys.argv) < 3:
        print("Usage: csuite-context-extract.py <role> <current-state-path>", file=sys.stderr)
        sys.exit(1)

    role = sys.argv[1].lower()
    filepath = sys.argv[2]

    try:
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    output = extract_for_role(content, role)
    print(output)


if __name__ == "__main__":
    main()
