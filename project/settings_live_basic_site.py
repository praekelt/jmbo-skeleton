from project.settings_live_base import *


SITE_ID = 2
STATIC_ROOT = abspath("..",  "skeleton-static", "basic")
STATIC_URL = '/static/basic/'

try:
    import local_settings
    from local_settings import *
except ImportError:
    pass
else:
    if hasattr(local_settings, 'configure'):
        lcl = locals()
        di = local_settings.configure(**locals())
        lcl.update(**di)
