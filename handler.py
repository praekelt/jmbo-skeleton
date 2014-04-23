import base64
import json

from twisted.internet.defer import inlineCallbacks, returnValue
from twisted.internet.error import ConnectError

from twisted.web.client import getPage
from devproxy.handlers.wurfl_handler.base import WurflHandler, WurflHandlerException
from devproxy.handlers.wurfl_handler.scientia_mobile_cloud \
    import ScientiaMobileCloudHandler


class ScientiaMobileCloudHandlerConnectError(Exception):
    pass


class ScientiaMobileCloudResolutionHandler(ScientiaMobileCloudHandler):
    """Can be simplified once device-proxy itself is improved"""

    @inlineCallbacks
    def get_headers(self, request):
        user_agent = unicode(request.getHeader('User-Agent') or '')

        # Return early if this is a bot that should not be redirected
        if user_agent in ('PageFetcher-Google-CoOp', 'Mozilla/5.0 (Java) outbrain'):
            # When X-Site-Type is 'mobi', default to 'basic'
            site_type = request.getHeader('X-Site-Type')
            layer = 'web' if site_type == 'web' else 'basic'
            returnValue([{self.header_name: layer}])

        cache_key = self.get_cache_key(user_agent)
        flags, cached = yield self.memcached.get(cache_key)
        if cached:
            headers = self.handle_request_from_cache(cached, request)
        else:
            headers = yield self.handle_request_and_cache(cache_key,
                user_agent, request)

        returnValue(headers)

    @inlineCallbacks
    def handle_request_and_cache(self, cache_key, user_agent, request):
        expireTime = self.cache_lifetime
        try:
            device = yield self.get_device_from_smcloud(user_agent)
        except ScientiaMobileCloudHandlerConnectError:
            device = {}
            expireTime = 60
        headers = self.handle_device(request, device)
        yield self.memcached.set(cache_key, json.dumps(headers),
                                 expireTime=expireTime)
        returnValue(headers)

    @inlineCallbacks
    def get_device_from_smcloud(self, user_agent):
        """
        Queries ScientiaMobile's API and returns a dictionary of the device.
        """
        # create basic auth string
        b64 = base64.encodestring(self.smcloud_api_key).strip()
        headers = {
            #User-Agent is set by agent in getPage.
            'X-Cloud-Client': self.SMCLOUD_CONFIG['client_version'],
            'Authorization': 'Basic %s' % b64
        }
        try:
            page = yield getPage(self.SMCLOUD_CONFIG['url'], headers=headers,
                             agent=user_agent, timeout=5)
        except ConnectError, exc:
            raise ScientiaMobileCloudHandlerConnectError(exc)
        device = json.loads(page)
        returnValue(device)

    def handle_device(self, request, device):
        # Set default (todo: get from settings)
        result = {
            self.header_name: 'web',
        }

        is_web_browser = False
        is_smart_browser = False
        is_basic_browser = False
        try:
            is_web_browser = device['capabilities']['ux_full_desktop'] or device['capabilities']['is_tablet']
            is_smart_browser = (device['capabilities']['resolution_width'] >= 320) \
                and (device['capabilities']['pointing_method'] == 'touchscreen')
            is_basic_browser = not (is_web_browser or is_smart_browser)
        except KeyError:
            pass

        if is_web_browser:
            result[self.header_name] = 'web'
        elif is_smart_browser:
            result[self.header_name] = 'smart'
        elif is_basic_browser:
            result[self.header_name] = 'basic'

        return [result]
