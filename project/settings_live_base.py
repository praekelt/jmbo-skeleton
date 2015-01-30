from project.settings import *


DEBUG = False
TEMPLATE_DEBUG = DEBUG

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': 'skeleton',
        'USER': 'skeleton',
        'PASSWORD': 'skeleton',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

MEDIA_ROOT = '%s/../skeleton-media/' % BUILDOUT_PATH

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
        'KEY_PREFIX': 'skeleton_live',
    }
}

CKEDITOR_UPLOAD_PATH = '%s/../skeleton-media/uploads/' % BUILDOUT_PATH

COMPRESS_ENABLED = True

SENTRY_DSN = 'ENTER_YOUR_SENTRY_DSN_HERE'
SENTRY_CLIENT = 'raven.contrib.django.celery.CeleryClient'
