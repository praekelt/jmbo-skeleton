from project.settings_qa_base import *


LAYERS['layers'] = ('basic', 'smart')
SITE_ID = 4
STATIC_ROOT = abspath("..",  "skeleton-static", "web")
STATIC_URL = '/static/smart/'
