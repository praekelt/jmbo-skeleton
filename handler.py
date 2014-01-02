import base64
import json

from twisted.internet.defer import inlineCallbacks, returnValue
from twisted.internet.error import ConnectError

from twisted.web.client import getPage
from devproxy.handlers.wurfl_handler.base import WurflHandler, WurflHandlerException
from devproxy.handlers.wurfl_handler.scientia_mobile_cloud \
    import ScientiaMobileCloudHandler


class WebMobiHandler(WurflHandler):
    """Used for a site with both web and mobi"""

    @inlineCallbacks
    def get_headers(self, request):
        user_agent = unicode(request.getHeader('User-Agent') or '')
        cache_key = self.get_cache_key(user_agent)
        flags, cached = yield self.memcached.get(cache_key)
        if cached:
            headers = self.handle_request_from_cache(cached, request)
        else:
            headers = yield self.handle_request_and_cache(cache_key,
                user_agent, request)

        is_web_browser = bool(headers[0]['is_web_browser'])
        is_mobi_browser = not is_web_browser
        site_type = request.getHeader('X-Site-Type')

        # This makes it possible for a mobi browser to request the full site,
        # and also to go back to the mobi site.
        if site_type == 'web':
            headers[0][self.header_name] = 'web'
            if request.uri.find('showsite=web') != -1:
                request.addCookie('show_web', '1')
            elif request.uri.find('showsite=mobi') != -1:
                request.addCookie('show_web', '')
                headers[0]['X-redirect-to-mobi'] = '1'
            elif is_mobi_browser:
                if not request.getCookie('show_web'):
                    headers[0]['X-redirect-to-mobi'] = '1'

        elif site_type == 'mobi':
            if request.uri.find('showsite=web') != -1:
                request.addCookie('show_web', '1')
                headers[0]['X-redirect-to-web'] = '1'
            elif request.uri.find('showsite=mobi') != -1:
                request.addCookie('show_web', '')
            elif request.getCookie('show_web'):
                headers[0]['X-redirect-to-web'] = '1'

        returnValue(headers)

    def handle_device(self, request, device):
        result = {
            'is_web_browser': device.devid in ('generic_web_browser', 'generic_web_crawler') and '1' or '',
            self.header_name: 'basic'
        }

        if (device.resolution_width >= 320) \
            and (device.pointing_method == 'touchscreen'):
            result[self.header_name] = 'smart'

        return [result]


class WebHandler(WurflHandler):
    """Used for a web only site"""

    def handle_device(self, request, device):
        return [{self.header_name: 'web'}]


class MobiHandler(WurflHandler):
    """Used for a mobi only site"""

    def handle_device(self, request, device):
        result = {self.header_name: 'basic'}

        if (device.resolution_width >= 320) \
            and (device.pointing_method == 'touchscreen'):
            result[self.header_name] = 'smart'

        return [result]


class ScientiaMobileCloudHandlerConnectError(Exception):
    pass


class ScientiaMobileCloudResolutionHandler(ScientiaMobileCloudHandler):
    """todo: contribute handle_request_and_cache and get_device_from_smcloud
    back to deviceproxy"""

    @inlineCallbacks
    def get_headers(self, request):
        user_agent = unicode(request.getHeader('User-Agent') or '')

        # Handling for devices not yet recognized by the Wurfl service.
        # Return early if this is a bot that should not be redirected.
        if 'PageFetcher-Google-CoOp' in user_agent:
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

        is_web_browser = bool(headers[0]['is_web_browser'])
        is_mobi_browser = not is_web_browser
        site_type = request.getHeader('X-Site-Type')

        # This makes it possible for a mobi browser to request the full site,
        # and also to go back to the mobi site.
        if site_type == 'web':
            headers[0][self.header_name] = 'web'
            if request.uri.find('showsite=web') != -1:
                request.addCookie('show_web', '1')
            elif request.uri.find('showsite=mobi') != -1:
                request.addCookie('show_web', '')
                headers[0]['X-redirect-to-mobi'] = '1'
            elif is_mobi_browser:
                if not request.getCookie('show_web'):
                    headers[0]['X-redirect-to-mobi'] = '1'

        elif site_type == 'mobi':
            if request.uri.find('showsite=web') != -1:
                request.addCookie('show_web', '1')
                headers[0]['X-redirect-to-web'] = '1'
            elif request.uri.find('showsite=mobi') != -1:
                request.addCookie('show_web', '')
            elif request.getCookie('show_web'):
                headers[0]['X-redirect-to-web'] = '1'

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
        result = {
            'is_web_browser': '1',
            self.header_name: 'basic'
        }

        try:
            result = {
                'is_web_browser': (device['capabilities']['ux_full_desktop'] or device['capabilities']['is_tablet']) and '1' or '',
                self.header_name: 'basic'
            }
            if (device['capabilities']['resolution_width'] >= 320) \
                and (device['capabilities']['pointing_method'] == 'touchscreen'):
                result[self.header_name] = 'smart'
        except KeyError:
            pass

        return [result]
