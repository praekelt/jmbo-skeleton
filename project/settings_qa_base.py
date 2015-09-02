from project.settings import *


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
        'KEY_PREFIX': 'skeleton_qa',
    }
}

# Uncomment to use atlas. Remember to change the database engine to GIS aware.
#INSTALLED_APPS += ("atlas", "django.contrib.gis")

ALLOWED_HOSTS = [
    "*"
]
