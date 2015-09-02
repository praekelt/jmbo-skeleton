from project.settings_qa_base import *


LAYERS['layers'] = ('basic', 'web')
STATIC_ROOT = abspath("..",  "skeleton-static", "web")
STATIC_URL = '/static/web/'

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
