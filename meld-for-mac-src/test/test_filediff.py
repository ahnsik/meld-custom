
from unittest import mock

import pytest
from gi.repository import Gtk


@pytest.mark.parametrize("text, ignored_ranges, expected_text", [
    #    0123456789012345678901234567890123456789012345678901234567890123456789
    # Matching without groups
    (
        "# asdasdasdasdsad",
        [(0, 17)],
        "",
    ),
    # Matching with single group
    (
        "asdasdasdasdsab",
        [(1, 14)],
        "ab",
    ),
    # Matching with multiple groups
    (
        "xasdyasdz",
        [(1, 4), (5, 8)],
        "xyz",
    ),
    # Matching with multiple partially overlapping filters
    (
        "qaqxqbyqzq",
        [(2, 6), (7, 8)],
        "qayzq",
    ),
    # Matching with multiple fully overlapping filters
    (
        "qaqxqybqzq",
        [(2, 8)],
        "qazq",
    ),
    # Matching with and without groups, with single dominated match
    (
        "# asdasdasdasdsab",
        [(0, 17)],
        "",
    ),
    # Matching with and without groups, with partially overlapping filters
    (
        "/*a*/ub",
        [(0, 6)],
        "b",
    ),
    # Non-matching with groups
    (
        "xasdyasdx",
        [],
        "xasdyasdx",
    ),
    # Multiple lines with non-overlapping filters
    (
        "#ab\na2b",
        [(0, 3), (5, 6)],
        "\nab",
    ),
    # CVS keyword
    (
        "$Author: John Doe $",
        [(8, 18)],
        "$Author:$",
    ),

])
def test_filter_text(text, ignored_ranges, expected_text):
    from meld.filediff import FileDiff
    from meld.filters import FilterEntry

    filter_patterns = [
        '#.*',
        r'/\*.*\*/',
        'a(.*)b',
        'x(.*)y(.*)z',
        r'\$\w+:([^\n$]+)\$'
    ]
    filters = [
        FilterEntry.new_from_gsetting(("name", True, f), FilterEntry.REGEX)
        for f in filter_patterns
    ]

    filediff = mock.MagicMock()
    filediff.text_filters = filters
    filter_text = FileDiff._filter_text

    buf = Gtk.TextBuffer()
    buf.create_tag("inline")
    buf.create_tag("dimmed")
    buf.set_text(text)
    start, end = buf.get_bounds()

    text = filter_text(
        filediff, buf.get_text(start, end, False), buf, start, end)

    # Find ignored ranges
    tag = buf.get_tag_table().lookup("dimmed")
    toggles = []
    it = start.copy()
    if it.toggles_tag(tag):
        toggles.append(it.get_offset())
    while it.forward_to_tag_toggle(tag):
        toggles.append(it.get_offset())
    toggles = list(zip(toggles[::2], toggles[1::2]))

    print("Text:", text)
    print("Toggles:", toggles)

    assert toggles == ignored_ranges
    assert text == expected_text


@pytest.mark.parametrize(
    "direction, expected_panes",
    [(-1, (1, 0)), (1, (0, 1))],
)
def test_push_change_and_go_next(direction, expected_panes):
    from meld.filediff import FileDiff

    filediff = mock.MagicMock()
    filediff.num_panes = 2
    filediff.cursor.next = 2
    filediff.get_action_chunk.return_value = "current chunk"

    def refresh_cursor(*args):
        filediff.cursor.next = 1

    filediff.on_cursor_position_changed.side_effect = refresh_cursor

    FileDiff._push_change_and_go_next(filediff, direction)

    src, dst = expected_panes
    filediff.replace_chunk.assert_called_once_with(
        src, dst, "current chunk")
    filediff.on_cursor_position_changed.assert_called_once_with(
        filediff.focus_pane.get_buffer(), None, True)
    filediff.go_to_chunk.assert_called_once_with(1)
