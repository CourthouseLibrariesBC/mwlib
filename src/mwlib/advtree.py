# Copyright (c) 2007-2009 PediaPress GmbH
# See README.rst for additional licensing information.

"""
The parse tree generated by the parser is a 1:1
representation of the mw-markup.
Unfortunately these trees have
some flaws if used to generate derived documents.

This module seeks to rebuild the parstree
to be:
 * more logical markup
 * clean up the parse tree
 * make it more accessible
 * allow for validity checks
 * implement rebuilding strategies

Useful Documentation:
http://en.wikipedia.org/wiki/Wikipedia:Don%27t_use_line_breaks
http://meta.wikimedia.org/wiki/Help:Advanced_editing
http://meta.wikimedia.org/wiki/Help:HTML_in_wikitext
"""


import copy
import re

import six

from mwlib.log import Log
from mwlib.parser import (
    URL,
    Article,
    ArticleLink,
    Book,
    Caption,
    CategoryLink,
    Cell,
    Chapter,
    ImageLink,
    InterwikiLink,
    Item,
    ItemList,
    LangLink,
    Link,
    Math,
    NamedURL,
    NamespaceLink,
    Node,
    Paragraph,
    PreFormatted,
    Ref,
    Row,
    Section,
    SpecialLink,
    Style,
    Table,
    TagNode,
    Text,
    Timeline,
)

log = Log("advtree")


def _id_index(lst, element_to_check):
    """Return index of first appeareance of element el in list lst"""

    for i, element in enumerate(lst):
        if element is element_to_check:
            return i
    raise ValueError("element %r not found" % element_to_check)


def debug(method):  # use as decorator
    def foo(self, *args, **kargs):
        log(f"\n{method.__name__} called with {args!r} {kargs!r}")
        log(f"on {self!r} attrs:{self.attributes!r} style:{self.style!r}")
        parent = self
        while parent.parent:
            parent = parent.parent
            log("%r" % parent)
        return method(self, *args, **kargs)

    return foo


class AdvancedNode:
    """Mixin Class that extends Nodes so they become easier accessible.

    Allows to traverse the tree in any direction and
    build derived convinience functions
    """

    parent = None  # parent element
    is_block_node = False

    def copy(self):
        "return a copy of this node and all its children"
        parent = self.parent
        try:
            self.parent = None
            node = copy.deepcopy(self)
        finally:
            self.parent = parent
        return node

    def move_to(
        self, targetnode, prefix=False
    ):  # FIXME: bad name. rename to moveBehind, and create method moveBefore
        """Move this node behind the target node.

        If prefix is true, move before the target node.
        """

        if self.parent:
            self.parent.remove_child(self)
        target_parent = targetnode.parent
        idx = _id_index(target_parent.children, targetnode)
        if not prefix:
            idx += 1
        target_parent.children.insert(idx, self)
        self.parent = target_parent

    def has_child(self, child):
        """Check if node c is child of self"""
        try:
            _id_index(self.children, child)
            if child.parent is not self:
                raise ValueError("child not found")
            return True
        except ValueError:
            return False

    def append_child(self, child):
        self.children.append(child)
        child.parent = self

    def remove_child(self, child):
        self.replace_child(child, [])
        if child.parent is not None:
            raise ValueError("child not removed")

    def replace_child(self, child, newchildren=[]):
        """Remove child node c and replace with newchildren if given."""

        idx = _id_index(self.children, child)
        self.children[idx: idx + 1] = newchildren

        child.parent = None
        if self.has_child(child):
            raise ValueError("child not removed")
        for new_child in newchildren:
            new_child.parent = self

    def get_parents(self):
        """Return list of parent nodes up to the root node.

        The returned list starts with the root node.
        """

        parents = []
        node = self.parent
        while node:
            parents.append(node)
            node = node.parent
        parents.reverse()
        return parents

    def get_parent(self):
        """Return the parent node"""
        return self.parent

    def get_level(self):
        """Returns the number of nodes of same class in parents"""
        return [p.__class__ for p in self.get_parents()].count(self.__class__)

    def get_parent_nodes_by_class(self, klass):
        """returns parents w/ klass"""
        return [p for p in self.parents if p.__class__ == klass]

    def get_child_nodes_by_class(self, klass):
        """returns all children  w/ klass"""
        return [p for p in self.get_all_children() if p.__class__ == klass]

    def get_all_children(self):
        """don't confuse w/ Node.allchildren()
        which returns allchildren + self"""
        for child in self.children:
            yield child
            yield from child.get_all_children()

    def get_siblings(self):
        """Return all siblings WITHOUT self"""
        return [child for child in self.get_all_siblings() if child is not self]

    def get_all_siblings(self):
        """Return all siblings plus self"""
        if self.parent:
            return self.parent.children
        return []

    def get_previous(self):
        """Return previous sibling"""
        sibling = self.get_all_siblings()
        try:
            idx = _id_index(sibling, self)
        except ValueError:
            return None
        if idx - 1 < 0:
            return None
        else:
            return sibling[idx - 1]

    def get_next(self):
        """Return next sibling"""
        sibling = self.get_all_siblings()
        try:
            idx = _id_index(sibling, self)
        except ValueError:
            return None
        if idx + 1 >= len(sibling):
            return None
        else:
            return sibling[idx + 1]

    def get_last(self):  # FIXME might return self. is this intended?
        """Return last sibling"""
        sibling = self.get_all_siblings()
        if sibling:
            return sibling[-1]

    def get_first(self):  # FIXME might return self. is this intended?
        """Return first sibling"""
        sibling = self.get_all_siblings()
        if sibling:
            return sibling[0]

    def get_last_child(self):
        """Return last child of this node"""
        if self.children:
            return self.children[-1]

    def get_first_child(self):
        "Return first child of this node"
        if self.children:
            return self.children[0]

    def get_first_leaf(self, caller_is_self=True):
        """Return 'first' child that has no children itself"""
        if self.children:
            # first kid of a section is its caption
            if self.__class__ == Section:
                if len(self.children) == 1:
                    return None
                else:
                    return self.children[1].get_first_leaf(caller_is_self=False)
            else:
                return self.children[0].get_first_leaf(caller_is_self=False)
        else:
            if caller_is_self:
                return None
            else:
                return self

    def get_last_leaf(self, caller_is_self=True):
        """Return 'last' child that has no children itself"""
        if self.children:
            return self.children[-1].get_first_leaf(caller_is_self=False)
        else:
            if caller_is_self:
                return None
            else:
                return self

    def get_all_display_text(self, amap=None):
        "Return all text that is intended for display"
        text = []
        if not amap:
            amap = {
                Text: "caption",
                Link: "target",
                URL: "caption",
                Math: "caption",
                ImageLink: "caption",
                ArticleLink: "target",
                NamespaceLink: "target",
            }
        skip_on_children = [Link, NamespaceLink]
        for node in self.allchildren():
            access = amap.get(node.__class__, "")
            if access:
                if node.__class__ in skip_on_children and node.children:
                    continue
                text.append(getattr(node, access))
        alltext = [t for t in text if t]
        if alltext:
            return "".join(alltext)
        else:
            return ""

    def get_style(self):
        if not self.attributes:
            return {}
        else:
            return self.attributes.get("style", {})

    def _ensure_int(self, val, min_val=1):
        try:
            return max(min_val, int(val))
        except ValueError:
            return min_val

    def _ensure_unicode(self, val):
        if isinstance(val, six.text_type):
            return val
        elif isinstance(val, str):
            return six.text_type(val, "utf-8")
        else:
            try:
                return six.text_type(val)
            except BaseException:
                return ""

    def _ensure_dict(self, val):
        if isinstance(val, dict):
            return val
        else:
            return {}

    def _clean_attrs(self, attrs):
        for key, value in attrs.items():
            if key in ["colspan", "rowspan"]:
                attrs[key] = self._ensure_int(value, min_val=1)
            elif key == "style":
                attrs[key] = self._clean_attrs(self._ensure_dict(value))
            else:
                attrs[key] = self._ensure_unicode(value)
        return attrs

    def get_attributes(self):
        """Return dict with node attributes
        (e.g. class, style, colspan etc.)"""
        vlist = getattr(self, "vlist", None)
        if vlist is None:
            self.vlist = vlist = {}

        attrs = self._clean_attrs(vlist)
        return attrs

    def has_class_id(self, class_ids):
        _class = self.attributes.get("class", "").split(" ")
        _id = self.attributes.get("id", "")
        return any(classID in _class or classID == _id for classID in class_ids)

    def is_visible(self):
        """Return True if node is visble. Used to detect hidden elements."""
        if self.style.get("display", "").lower() == "none":
            return False
        if self.style.get("visibility", "").lower() == "hidden":
            return False
        return True

    style = property(get_style)
    attributes = property(get_attributes)
    visible = property(is_visible)

    parents = property(get_parents)
    next = property(get_next)
    previous = property(get_previous)
    siblings = property(get_siblings)
    last = property(get_last)
    first = property(get_first)
    lastchild = property(get_last_child)
    firstchild = property(get_first_child)


# --------------------------------------------------------------------------
# MixinClasses w/ special behaviour
# -------------------------------------------------------------------------


class AdvancedTable(AdvancedNode):
    @property
    def rows(self):
        return [r for r in self if r.__class__ == Row]

    @property
    def numcols(self):
        max_cols = 0
        for row in self.children:
            cols = sum(
                [
                    cell.attributes.get("colspan", 1)
                    for cell in row.children
                    if not getattr(cell, "colspanned", False)
                ]
            )
            max_cols = max(max_cols, cols)
        return max_cols


class AdvancedRow(AdvancedNode):
    @property
    def cells(self):
        return [child for child in self if child.__class__ == Cell]


class AdvancedCell(AdvancedNode):
    @property
    def colspan(self, attr="colspan"):
        """colspan of cell. result is always non-zero, positive int"""
        return self.attributes.get("colspan") or 1

    @property
    def rowspan(self):
        """rowspan of cell. result is always non-zero, positive int"""
        return self.attributes.get("rowspan") or 1


class AdvancedSection(AdvancedNode):
    def get_section_level(self):
        return 1 + self.get_level()


class AdvancedImageLink(AdvancedNode):
    is_block_node = property(lambda s: not s.is_inline())

    @property
    def render_caption(self):
        explicit_caption = bool(
            getattr(self, "thumb") or getattr(self, "frame", "") == "frame"
        )
        is_gallery = len(self.get_parent_nodes_by_class(Gallery)) > 0
        has_children = len(self.children) > 0
        return (explicit_caption or is_gallery) and has_children


class AdvancedMath(AdvancedNode):
    @property
    def is_block_node(self):
        if self.caption.strip().startswith(
            "\\begin{align}"
        ) or self.caption.strip().startswith("\\begin{alignat}"):
            return True
        return False


# --------------------------------------------------------------------------
# Missing as Classes derived from parser.Style
# -------------------------------------------------------------------------


class Italic(Style, AdvancedNode):
    _tag = "i"


class Emphasized(Style, AdvancedNode):
    _tag = "em"


class Strong(Style, AdvancedNode):
    _tag = "strong"


class DefinitionList(Style, AdvancedNode):
    _tag = "dl"


class DefinitionTerm(Style, AdvancedNode):
    _tag = "dt"


class DefinitionDescription(Style, AdvancedNode):
    _tag = "dd"


class Blockquote(Style, AdvancedNode):
    "margins to left &  right"
    _tag = "blockquote"


class Indented(
    Style, AdvancedNode
):  # fixme: node is deprecated, now style node ':' always becomes a DefinitionDescription
    """margin to the left"""

    def get_indent_level(self):
        return self.caption.count(":")

    indentlevel = property(get_indent_level)


class Overline(Style, AdvancedNode):
    _style = "overline"


class Underline(Style, AdvancedNode):
    _style = "u"


class Sub(Style, AdvancedNode):
    _style = "sub"
    _tag = "sub"


class Sup(Style, AdvancedNode):
    _style = "sup"
    _tag = "sup"


class Small(Style, AdvancedNode):
    _style = "small"
    _tag = "small"


class Big(Style, AdvancedNode):
    _style = "big"
    _tag = "big"


class Cite(Style, AdvancedNode):
    _style = "cite"
    _tag = "cite"


class Var(Style, AdvancedNode):
    _tag = "var"
    _style = "var"


_styleNodeMap = {
    k._style: k for k in [Overline, Underline, Sub, Sup, Small, Big, Cite, Var]
}

# --------------------------------------------------------------------------
# Missing as Classes derived from parser.TagNode
# http://meta.wikimedia.org/wiki/Help:HTML_in_wikitext
# -------------------------------------------------------------------------


class Source(TagNode, AdvancedNode):
    _tag = "source"


class Code(TagNode, AdvancedNode):
    _tag = "code"


class BreakingReturn(TagNode, AdvancedNode):
    _tag = "br"


class HorizontalRule(TagNode, AdvancedNode):
    _tag = "hr"


class Index(TagNode, AdvancedNode):
    _tag = "index"


class Teletyped(TagNode, AdvancedNode):
    _tag = "tt"


class Reference(TagNode, AdvancedNode):
    _tag = "ref"


class ReferenceList(TagNode, AdvancedNode):
    _tag = "references"


class Gallery(TagNode, AdvancedNode):
    _tag = "gallery"


class Center(TagNode, AdvancedNode):
    _tag = "center"


class Div(TagNode, AdvancedNode):
    _tag = "div"


class Span(
    TagNode, AdvancedNode
):  # span is defined as inline node which is in theory correct.
    _tag = "span"


class Font(TagNode, AdvancedNode):
    _tag = "font"


class Strike(TagNode, AdvancedNode):
    _tag = "strike"


# class S(TagNode, AdvancedNode):
#     _tag = "s"


class ImageMap(TagNode, AdvancedNode):  # defined as block node, maybe incorrect
    _tag = "imagemap"


class Ruby(TagNode, AdvancedNode):
    _tag = "ruby"


class RubyBase(TagNode, AdvancedNode):
    _tag = "rb"


class RubyParentheses(TagNode, AdvancedNode):
    _tag = "rp"


class RubyText(TagNode, AdvancedNode):
    _tag = "rt"


class Deleted(TagNode, AdvancedNode):
    _tag = "del"


class Inserted(TagNode, AdvancedNode):
    _tag = "ins"


class TableCaption(TagNode, AdvancedNode):
    _tag = "caption"


class Abbreviation(TagNode, AdvancedNode):
    _tag = "abbr"


_tagNodeMap = {
    k._tag: k
    for k in [
        Abbreviation,
        BreakingReturn,
        Center,
        Code,
        DefinitionDescription,
        DefinitionList,
        DefinitionTerm,
        Deleted,
        Div,
        Font,
        Gallery,
        HorizontalRule,
        ImageMap,
        Index,
        Inserted,
        Reference,
        ReferenceList,
        Ruby,
        RubyBase,
        RubyText,
        Source,
        Span,
        Strike,
        TableCaption,
        Teletyped,
    ]
}
_styleNodeMap["s"] = Strike  # Special Handling for deprecated s style
_tagNodeMap["kbd"] = Teletyped

# --------------------------------------------------------------------------
# BlockNode separation for AdvancedNode.is_block_node
# -------------------------------------------------------------------------

"""
For writers it is useful to know whether elements are inline (within a paragraph) or not.
We define list for blocknodes, which are used in AdvancedNode as:

AdvancedNode.is_block_node

Image depends on result of Image.is_inline() see above

Open Issues: Math, Magic, (unknown) TagNode

"""
_blockNodes = (
    Article,
    Blockquote,
    Book,
    BreakingReturn,
    Cell,
    Center,
    Chapter,
    DefinitionDescription,
    DefinitionList,
    DefinitionTerm,
    Div,
    Gallery,
    HorizontalRule,
    ImageMap,
    Indented,
    Item,
    ItemList,
    Paragraph,
    PreFormatted,
    ReferenceList,
    Row,
    Section,
    Source,
    Table,
    Timeline,
)

for k in _blockNodes:
    k.is_block_node = True


# --------------------------------------------------------------------------
# funcs for extending the nodes
# -------------------------------------------------------------------------


def mix_in_class(pyClass, mix_in_class, make_first=False):
    if mix_in_class not in pyClass.__bases__:
        if make_first:
            pyClass.__bases__ = (mix_in_class,) + pyClass.__bases__
        else:
            pyClass.__bases__ += (mix_in_class,)


def extend_classes(node):
    for child in node.children[:]:
        extend_classes(child)
        child.parent = node


# Nodes we defined above and that are separetly handled in extendClasses
_advancedNodesMap = {
    Section: AdvancedSection,
    ImageLink: AdvancedImageLink,
    Math: AdvancedMath,
    Cell: AdvancedCell,
    Row: AdvancedRow,
    Table: AdvancedTable,
}
mix_in_class(Node, AdvancedNode)
for k, v in _advancedNodesMap.items():
    mix_in_class(k, v)

# --------------------------------------------------------------------------
# Functions for fixing the parse tree
# -------------------------------------------------------------------------


def fix_tag_nodes(node):
    """Detect known TagNodes and and transfrom to appropriate Nodes"""
    for child in node.children:
        if child.__class__ == TagNode:
            if child.caption in _tagNodeMap:
                child.__class__ = _tagNodeMap[child.caption]
            elif child.caption in ("h1", "h2", "h3", "h4", "h5", "h6"):  # FIXME
                # NEED TO MOVE NODE IF IT REALLY STARTS A SECTION
                child.__class__ = Section
                mix_in_class(child.__class__, AdvancedSection)
                child.level = int(child.caption[1])
                child.caption = ""
            else:
                log.warn("fixTagNodes, unknowntagnode %r" % child)
        fix_tag_nodes(child)


def fix_style_node(node):
    """
    parser.Style Nodes are mapped to logical markup
    detection of DefinitionList depends on remove_nodes
    and remove_new_lines
    """
    if node.__class__ != Style:
        return
    if node.caption == "''":
        node.__class__ = Emphasized
        node.caption = ""
    elif node.caption == "'''''":
        node.__class__ = Strong
        node.caption = ""
        emphasized = Emphasized("''")
        for child in node.children:
            emphasized.append_child(child)
        node.children = []
        node.append_child(emphasized)
    elif node.caption == "'''":
        node.__class__ = Strong
        node.caption = ""
    elif node.caption == ";":
        node.__class__ = DefinitionTerm
        node.caption = ""
    elif node.caption.startswith(":"):
        node.__class__ = DefinitionDescription
        node.indentlevel = len(re.findall("^:+", node.caption)[0])
        node.caption = ""
    elif node.caption == "-":
        node.__class__ = Blockquote
        node.caption = ""
    elif node.caption in _styleNodeMap:
        node.__class__ = _styleNodeMap[node.caption]
        node.caption = ""
    else:
        log.warn("fixStyle, unknownstyle %r" % node)
        return node

    return node


def fix_style_nodes(node):
    if node.__class__ == Style:
        fix_style_node(node)
    for child in node.children[:]:
        fix_style_nodes(child)


def remove_nodes(node):
    """
    the parser generates empty Node elements that do
    nothing but group other nodes. we remove them here
    """
    if node.__class__ == Node and not (
        node.previous is None and node.parent.__class__ == Section
    ):
        # first child of section groups heading text - grouping Node must not be removed
        node.parent.replace_child(node, node.children)

    for child in node.children[:]:
        remove_nodes(child)


def remove_newlines(node):
    """
    remove newlines, tabs, spaces if we are next to a blockNode
    """
    if node.__class__ in (PreFormatted, Source):
        return

    todo = [node]
    while todo:
        node = todo.pop()
        if node.__class__ is Text and node.caption:
            if not node.caption.strip():
                prev = (
                    node.previous or node.parent
                )  # previous sibling node or parentnode
                next_node = node.next or node.parent.next
                if (
                    not next_node
                    or next_node.is_block_node
                    or not prev
                    or prev.is_block_node
                ):
                    node.parent.remove_child(node)
            node.caption = node.caption.replace("\n", " ")

        for child in node.children:
            if child.__class__ in (PreFormatted, Source):
                continue
            todo.append(child)


def build_advanced_tree(root):  # USE WITH CARE
    """
    extends and cleans parse trees
    do not use this funcs without knowing whether these
    Node modifications fit your problem
    """
    functions = [
        extend_classes,
        fix_tag_nodes,
        remove_nodes,
        remove_newlines,
        fix_style_nodes,
    ]
    for fun in functions:
        fun(root)


def _validate_parser_tree(node, parent=None):
    # helper to assert tree parent link consistency
    if parent is not None:
        _id_index(parent.children, node)  # asserts it occures only once
    for child in node:
        _id_index(node.children, child)  # asserts it occures only once
        if child not in node.children:
            raise ValueError(f"child {child!r} not in children of {node!r}")
        _validate_parser_tree(child, node)


def _validate_parents(node, parent=None):
    # helper to assert tree parent link consistency
    if parent is not None:
        if not parent.has_child(node):
            raise ValueError(f"parent {parent!r} has no child {node!r}")
    else:
        if node.parent is not None:
            raise ValueError(f"node {node!r} has parent {node.parent!r}")
    for child in node:
        if not node.has_child(child):
            raise ValueError(f"node {node!r} has no child {child!r}")
        _validate_parents(child, node)


def get_advanced_tree(fun):
    from mwlib.dummydb import DummyDB
    from mwlib.uparser import parse_string

    database = DummyDB()
    with open(fun) as wiki_file:
        tree_input = six.text_type(wiki_file.read(), "utf8")
    parsed_string = parse_string(title=fun, raw=tree_input, wikidb=database)
    build_advanced_tree(parsed_string)
    return parsed_string


def simpleparse(raw):  # !!! USE FOR DEBUGGING ONLY !!!
    import sys

    from mwlib import dummydb, parser
    from mwlib.uparser import parse_string

    decoded_input = raw.decode("utf8")
    parsed_string = parse_string(title="title", raw=decoded_input, wikidb=dummydb.DummyDB())
    build_advanced_tree(parsed_string)
    parser.show(sys.stdout, parsed_string, 0)
    return parsed_string
