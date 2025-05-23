#! /usr/bin/env py.test

# Copyright (c) 2007-2009 PediaPress GmbH
# See README.rst for additional licensing information.

from mwlib import parser
from mwlib.parser.refine import uparser

parse = uparser.simpleparse


def test_rot13():
    r = parse("""<rot13>test</rot13>""")  # grfg
    txt = [x.caption for x in r.find(parser.Text)]
    assert txt == ["rot13(test) is grfg"]


def test_idl():
    stuff = "\n\t\ta:=b '''c''' v"
    r = parse("""<idl>%s</idl>""" % stuff)
    tn = r.find(parser.TagNode)[0]
    assert isinstance(tn, parser.TagNode)
    assert tn.caption == "source"
    assert tn.vlist["lang"] == "idl"
    for c in tn.children[0].children:
        assert isinstance(c, parser.Text)
    assert stuff == "".join(c.caption for c in tn.children)


def test_syntaxhightlight():
    raw = """<syntaxhighlight lang="php">
<?php
    $v = "string";    // sample initialization
?>
html text
<?
    echo $v;         // end of php code
?>
</syntaxhighlight>

"""
    p = parse(raw)
    src = p.find(parser.TagNode)[0]
    assert src and src.tagname == "source", "Syntaxhighight node not treated as source"


def test_listing():
    raw = """
* <listing name="Attraction name" alt="local or alternative name" address="Address" directions="directions" phone="+91-22-2222-1234" email="fakeemail@fakehost.com" fax="+91-22-2222-1235" url="http://www.example.com" hours="9 pm -5:30 pm" price="Rs. 50 for entrance" lat="latitude" long="longitude" tags="comma,separated,tag_labels">Stuff about the attraction.</listing>"""
    r = parse(raw)
    all_children = list(r.allchildren())
    assert len(all_children) == 29
    assert "Stuff" in str(all_children[-1])


def test_rdf():
    raw = """<rdf>
    <> dc:source <http://www.example.com/some/upstream/document.txt>, Wikipedia:AnotherArticle .

    <http://www.example.com/some/upstream/document.txt>
      a cc:Work;
      dc:creator "Anne Example-Person", "Anne Uther-Person";
      dc:contributor "Yadda Nudda Person";
      dc:dateCopyrighted "14 Mar 2005";
      cc:License cc:by-sa-1.0.
 </rdf>"""

    r = parse(raw)
    assert not r.children


def test_poem():
    raw = """
<poem>
1bla bla
2bla bla
 3bla bla
4bla bla
</poem>
"""
    r = parse(raw)
    all_children = [str(x) for x in r.allchildren()]
    assert len(all_children) == 28
    assert "'1bla bla'" in all_children


def test_section():
    raw = """
a <section begin=chapter1/> 1bla bla <section end=chapter1/> bla
"""
    r = parse(raw)
    all_children = [str(x) for x in r.allchildren()]
    assert len(all_children) == 6
    assert "' 1bla bla '" in all_children
