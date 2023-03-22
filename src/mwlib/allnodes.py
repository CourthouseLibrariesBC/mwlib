from __future__ import absolute_import

import types

import mwlib.advtree
import mwlib.parser


def allnodes():
    all = set()
    names = set()
    for m in (mwlib.parser, mwlib.advtree):
        for x in dir(m):
            if x in names:
                continue
            k = getattr(m, x)
            if isinstance(k, type):
                if issubclass(k, mwlib.parser.Node):
                    all.add(k)
                    names.add(x)
    return all


if __name__ == "__main__":
    # EXAMPLE THAT SHOWS HOW TO IDENTIFY MISSING NODES
    from mwlib.parser import Control, Chapter

    my = set((Control, Chapter))
    missing = allnodes() - my
    assert len(missing) == len(allnodes()) - 2
    # print missing