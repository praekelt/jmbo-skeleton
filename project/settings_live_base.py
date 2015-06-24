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

MEDIA_ROOT = abspath("..",  "skeleton-media")
STATIC_ROOT = abspath("..",  "skeleton-static")
CKEDITOR_UPLOAD_PATH = os.path.join(MEDIA_ROOT, "uploads")

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
        'KEY_PREFIX': 'skeleton_live',
    }
}

COMPRESS_ENABLED = True

INSTALLED_APPS += ("atlas", "django.contrib.gis")

SENTRY_DSN = 'ENTER_YOUR_SENTRY_DSN_HERE'
SENTRY_CLIENT = 'raven.contrib.django.celery.CeleryClient'

ALLOWED_HOSTS = [
    ".site.com"
]
