#! /usr/bin/env py.test

"""Unittests for mwlib.utils"""

import socket

import pytest

from mwlib.utils import unorganized


@pytest.mark.parametrize(
    "test_input,expected",
    [
        ("abc", "abc"),
        ("a b c", "a_b_c"),
        ("a\tb\tc", "abc"),
        ("ä", "~228~"),
        ("ł", "~322~"),
        ("~", "~~"),
        (b"~", "~~"),
        ("~abc", "~~abc"),
    ],
)
def test_fs_escape(test_input, expected):
    assert unorganized.fs_escape(test_input) == expected
    assert isinstance(unorganized.fs_escape(test_input), str)


def test_uid():
    uids = set()
    for _ in range(100):
        uid = unorganized.uid()
        assert uid not in uids
        uids.add(uid)
    for max_length in range(1, 20):
        assert len(unorganized.uid(max_length)) <= max_length


def test_report(monkeypatch):
    monkeypatch.setattr(socket, "getfqdn", lambda: "mwlib-server.org")
    data = unorganized.report(system="system123", subject="subject123", foo="foo123")
    assert "foo" in data
    assert "foo123" in data


def test_get_safe_url():
    g = unorganized.get_safe_url
    assert g('http://bla" target="_blank') is None
    assert g("http") is None
    assert g("http") is None
    assert g('http://bla/foo/bar" target="_blank') == "http://bla/foo/bar%22%20target%3D%22_blank"
    assert (
        g("http://xyz/wiki/%D0%91%D0%94%D0%A1%D0%9C") == "http://xyz/wiki/%D0%91%D0%94%D0%A1%D0%9C"
    )


def test_garble_password():
    x = unorganized.garble_password(["foo", "--password", "secret"])
    assert "secret" not in x
    unorganized.garble_password(["foo", "--password"])
    unorganized.garble_password(["foo"])
