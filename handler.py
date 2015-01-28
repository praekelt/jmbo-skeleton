from devproxy.handlers.wurfl_handler.scientia_mobile_cloud \
    import ScientiaMobileCloudResolutionTouchHandler


# The default handler distinguishes between basic, smart and web. See
# device-proxy for other handlers or create your own.
class MyHandler(ScientiaMobileCloudResolutionTouchHandler):
    pass
