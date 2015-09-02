from project.settings import *


DEBUG = False
TEMPLATE_DEBUG = DEBUG

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
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

# Uncomment to use atlas. Remember to change the database engine to GIS aware.
#INSTALLED_APPS += ("atlas", "django.contrib.gis")

SENTRY_DSN = 'ENTER_YOUR_SENTRY_DSN_HERE'
SENTRY_CLIENT = 'raven.contrib.django.celery.CeleryClient'
RAVEN_CONFIG = {
    'dsn': 'ENTER_YOUR_SENTRY_DSN_HERE',
}

ALLOWED_HOSTS = [
    "*"
]
