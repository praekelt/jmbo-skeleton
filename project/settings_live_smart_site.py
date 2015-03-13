from project.settings_live_base import *


LAYERS['layers'] = ('basic', 'smart')
SITE_ID = 4
STATIC_ROOT = abspath("..",  "skeleton-static", "smart")
STATIC_URL = '/static/smart/'
