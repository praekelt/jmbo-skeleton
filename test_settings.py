from skeleton.settings import *


DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.sqlite',
        'NAME': 'skeleton',
        'USER': 'test',
        'PASSWORD': '',
        'HOST': '',
        'PORT': '',
    }
}

CKEDITOR_UPLOAD_PATH = expanduser('~')

# Disable celery
CELERY_ALWAYS_EAGER = True
BROKER_BACKEND = 'memory'

# xxx: get tests to pass with migrations
SOUTH_TESTS_MIGRATE = False
