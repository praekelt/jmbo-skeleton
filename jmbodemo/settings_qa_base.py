from jmbodemo.settings import *


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'jmbodemo_qa',
        'USER': 'jmbodemo_qa',
        'PASSWORD': 'jmbodemo_qa',
        'HOST': '',
        'PORT': '',
    }
}

MEDIA_ROOT = '%s/../media-qa/' % BUILDOUT_PATH

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
        'KEY_PREFIX': 'jmbodemo_qa',
    }
}

CKEDITOR_UPLOAD_PATH = '%s/../media-qa/uploads/' % BUILDOUT_PATH
