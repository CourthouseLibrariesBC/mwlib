#! /usr/bin/env python

from __future__ import absolute_import
from __future__ import print_function
import sys
import six.moves.urllib.request, six.moves.urllib.parse, six.moves.urllib.error
try:
    import simplejson as json
except ImportError:
    import json


def fetch(lang):
    url = 'http://%s.wikipedia.org/w/api.php?action=query&meta=siteinfo&siprop=general|namespaces|namespacealiases|magicwords|interwikimap&format=json' % lang
    print('fetching %r' % url)
    data = six.moves.urllib.request.urlopen(url).read()
    fn = 'siteinfo-%s.json' % lang
    print('writing %r' % fn)
    data = json.loads(data)['query']
    json.dump(data, open(fn, 'wb'), indent=4, sort_keys=True)


def main(argv):
    languages = argv[1:]
    if not languages:
        languages = "de en es fr it ja nl no pl pt simple sv".split()

    for lang in languages:
        fetch(lang.lower())


if __name__ == '__main__':
    main(sys.argv)
