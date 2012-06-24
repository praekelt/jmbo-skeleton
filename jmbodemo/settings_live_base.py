from jmbodemo.settings import *


DEBUG = False
TEMPLATE_DEBUG = DEBUG

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'jmbodemo_live',
        'USER': 'jmbodemo_live',
        'PASSWORD': 'jmbodemo_live',
        'HOST': '',
        'PORT': '',
    }
}

MEDIA_ROOT = '%s/../media-live/' % BUILDOUT_PATH

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
        'KEY_PREFIX': 'jmbodemo_live',
    }
}

CKEDITOR_UPLOAD_PATH = '%s/../media-live/uploads/' % BUILDOUT_PATH

COMPRESS_ENABLED = True
