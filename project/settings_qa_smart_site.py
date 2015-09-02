from project.settings_qa_base import *


LAYERS['layers'] = ('basic', 'smart')
SITE_ID = 4
STATIC_ROOT = abspath("..",  "skeleton-static", "web")
STATIC_URL = '/static/smart/'

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
