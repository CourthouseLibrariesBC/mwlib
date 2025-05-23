from mwlib.parser.templ.marks import eqmark
from mwlib.parser.templ.node import Node


def _combine_string(node):
    # combine strings
    res = []
    tmp = []
    for optimized_node in (optimize(child_node) for child_node in node):
        if (
            isinstance(optimized_node, str)
            and optimized_node is not eqmark
        ):
            tmp.append(optimized_node)
        else:
            if tmp:
                res.append("".join(tmp))
                tmp = []
            res.append(optimized_node)
    if tmp:
        res.append("".join(tmp))
    node[:] = res


def optimize(node):
    if type(node) is tuple:
        return tuple(optimize(x) for x in node)

    if isinstance(node, str):
        return node

    if len(node) == 1 and type(node) in (list, Node):
        return optimize(node[0])

    if isinstance(node, Node):  # (Variable, Template, IfNode)):
        return node.__class__(tuple(optimize(x) for x in node))
    else:
        _combine_string(node)

    if len(node) == 1 and type(node) in (list, Node):
        return optimize(node[0])

    if isinstance(node, list):
        return tuple(node)

    return node
