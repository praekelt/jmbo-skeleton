from project.settings_qa_base import *


LAYERS['layers'] = ('basic', 'web')
STATIC_ROOT = abspath("..",  "skeleton-static", "web")
STATIC_URL = '/static/web/'
