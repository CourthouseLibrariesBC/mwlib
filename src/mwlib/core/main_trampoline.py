# nserve/nslave only monkeypatch when imported as __main__ so, we
# monkeypatch here and then call into the respective main function
from gevent import monkey

# ssl=False: Python 3.11's SSLContext.minimum_version setter recurses
# infinitely when gevent patches ssl. nginx handles TLS termination so
# nserve/nslave never need gevent-patched SSL for incoming connections;
# outgoing HTTPS (e.g. requests to pediapress) uses unpatched ssl fine.
monkey.patch_all(ssl=False)

from mwlib.apps.buildzip import main as buildzip_main_func  # noqa: E402
from mwlib.apps.render import main as render_main_func  # noqa: E402
from mwlib.core.nserve import main as nserve_main_func  # noqa: E402
from mwlib.core.nslave import main as nslave_main_func  # noqa: E402
from mwlib.network.postman import main as postman_main_func  # noqa: E402


def nserve_main():
    return nserve_main_func()


def nslave_main():
    return nslave_main_func()


def postman_main():
    return postman_main_func()

def mw_zip_main():
    return buildzip_main_func()

def mw_render_main():
    return render_main_func()
