from twisted.internet.defer import inlineCallbacks, returnValue

from devproxy.handlers.wurfl_handler.base import WurflHandler
from devproxy.handlers.wurfl_handler.scientia_mobile_cloud \
    import ScientiaMobileCloudHandler


class DefaultHandler(WurflHandler):

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
            if request.uri.find('show=web') != -1:
                request.addCookie('show_web', '1')
            elif request.uri.find('show=mobi') != -1:
                request.addCookie('show_web', '')
                headers[0]['X-redirect-to-mobi'] = '1'
            elif is_mobi_browser:
                if not request.getCookie('show_web'):
                    headers[0]['X-redirect-to-mobi'] = '1'

        elif site_type == 'mobi':
            if request.uri.find('show=web') != -1:
                request.addCookie('show_web', '1')
                headers[0]['X-redirect-to-web'] = '1'
            elif request.uri.find('show=mobi') != -1:
                request.addCookie('show_web', '')
            elif request.getCookie('show_web'):
                headers[0]['X-redirect-to-web'] = '1'

        returnValue(headers)

    def handle_device(self, request, device):
        result = {
            'is_web_browser': device.devid == 'generic_web_browser' and '1' or '',
            self.header_name: 'basic'
        }

        if (device.resolution_width >= 320) \
            and (device.pointing_method == 'touchscreen'):
            result[self.header_name] = 'smart'

        return [result]


class ScientiaMobileCloudResolutionHandler(ScientiaMobileCloudHandler):

    def handle_device(self, request, device):
        result = {self.header_name: 'basic'}

        if (device.resolution_width >= 320) \
            and (device.pointing_method == 'touchscreen'):
            result[self.header_name] = 'smart'

        return [result]
