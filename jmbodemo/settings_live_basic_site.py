from foundry import settings as foundry_settings

from jmbodemo.settings_live_base import *


foundry_settings.compute_settings(sys.modules[__name__])
