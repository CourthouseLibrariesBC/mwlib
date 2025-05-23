#! /usr/bin/env py.test

import copy

from mwlib.network.siteinfo import get_siteinfo
from mwlib.parser.templ import parser

si = copy.deepcopy(get_siteinfo("en"))
del si["magicwords"]


def test_aliasmap_no_magicwords():
    parser.AliasMap(si)


def test_parser_no_magicwords():
    p = parser.Parser("some text", siteinfo=si)
    p.parse()
