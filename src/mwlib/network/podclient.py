"""Client to a Print-on-Demand partner service (e.g. pediapress.com)"""

import logging
import os
import urllib.parse

import requests

try:
    import simplejson as json
except ImportError:
    import json

from mwlib.utils import conf
from mwlib.utils.unorganized import get_multipart

log = logging.getLogger(__name__)


class PODClient:
    def __init__(self, posturl, redirecturl=None):
        self.posturl = posturl.encode("utf-8")
        self.redirecturl = redirecturl

    def _post(self, data, content_type=None):
        headers = {"Content-Type": content_type} if content_type is not None else {}
        print("POSTING TO:", self.posturl)
        jdata = json.dumps(data).encode("utf-8")
        return requests.post(self.posturl, data=jdata, headers=headers).content

    def post_status(self, status=None, progress=None, article=None, error=None):
        post_data = {}

        def setv(name, val):
            if val is None:
                return
            if not isinstance(val, str):
                val = val.encode("utf-8")
            post_data[name] = val

        setv("status", status)
        setv("error", error)
        setv("article", article)

        if progress is not None:
            post_data["progress"] = "%d" % progress

        encoded_post_data = urllib.parse.urlencode(post_data)
        self._post(encoded_post_data)

    def streaming_post_zipfile(self, filename, file_handler=None):
        posturl = self.posturl if isinstance(self.posturl, str) else self.posturl.decode("utf-8")
        with file_handler if file_handler else open(filename, "rb") as fh:
            fh.seek(0)
            files = {"collection": ("collection.zip", fh, "application/octet-stream")}
            response = requests.post(posturl, files=files)
        if response.status_code != 200:
            raise RuntimeError(f"Upload failed: {response.reason!r}")

    def post_zipfile(self, filename):
        with open(filename, "rb") as zip_file:
            content_type, data = get_multipart(
                "collection.zip", zip_file.read(), "collection"
            )
        log.info(
            "POSTing zipfile %r to %s (%d Bytes)" % (filename, self.posturl, len(data))
        )
        self._post(data, content_type=content_type)


def podclient_from_serviceurl(serviceurl):
    response = requests.post(
        serviceurl,
        data=b"any",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    ).json()
    return PODClient(response["post_url"], redirecturl=response["redirect_url"])
