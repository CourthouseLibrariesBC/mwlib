from __future__ import absolute_import
from __future__ import print_function
__version_info__ = (0, 16, 1)
display_version = version = __version__ = "0.16.1"
gitid = gitversion = ""


def main():
    import pkg_resources
    for r in ("mwlib", "mwlib.rl", "mwlib.ext", "mwlib.hiq"):
        try:
            v = pkg_resources.require(r)[0].version
            print(r, v)
        except BaseException:
            continue
