from project.settings_live_base import *


LAYERS['layers'] = ('web', 'basic',)
STATIC_ROOT = abspath("..",  "skeleton-static", "web")
STATIC_URL = '/static/web/'
