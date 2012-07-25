from foundry import settings as foundry_settings

from skeleton.settings import *


FOUNDRY['layers'] = ('smart', 'mid', 'basic')
SITE_ID = 2

foundry_settings.compute_settings(sys.modules[__name__])
