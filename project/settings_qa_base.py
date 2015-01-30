from project.settings import *


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
        'KEY_PREFIX': 'skeleton_qa',
    }
}

CKEDITOR_UPLOAD_PATH = '%s/../skeleton-media/uploads/' % BUILDOUT_PATH

ALLOWED_HOSTS = [
    ".site.com"
]
