from skeleton.settings import *


DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': 'skeleton_qa',
        'USER': 'skeleton_qa',
        'PASSWORD': 'skeleton_qa',
        'HOST': '',
        'PORT': '',
    }
}

MEDIA_ROOT = '%s/../media-qa/' % BUILDOUT_PATH

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
        'KEY_PREFIX': 'skeleton_qa',
    }
}

CKEDITOR_UPLOAD_PATH = '%s/../media-qa/uploads/' % BUILDOUT_PATH
