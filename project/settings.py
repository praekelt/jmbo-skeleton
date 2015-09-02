import os
import sys
from os import path


FOUNDRY = {
    'sms_gateway_api_key': '',
    'sms_gateway_password': '',
}

LAYERS = {
    'layers': ('basic',),
}

# Paths
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def abspath(*args):
    """convert relative paths to absolute paths relative to PROJECT_ROOT"""
    return os.path.join(PROJECT_ROOT, *args)

PROJECT_MODULE = 'skeleton'

DEBUG = True
TEMPLATE_DEBUG = DEBUG

# For Postgres (not location aware) do from command line
# echo "CREATE USER skeleton WITH PASSWORD 'skeleton'" | sudo -u postgres psql
# echo "CREATE DATABASE skeleton WITH OWNER skeleton ENCODING 'UTF8'" | sudo -u postgres psql

# For Postgres (location aware) do from command line
# echo "CREATE USER skeleton WITH PASSWORD 'skeleton'" | sudo -u postgres psql
# echo "CREATE DATABASE skeleton WITH OWNER skeleton ENCODING 'UTF8'" | sudo -u postgres psql
# echo "CREATE EXTENSION postgis" | sudo -u postgres psql skeleton
# echo "CREATE EXTENSION postgis_topology" | sudo -u postgres psql skeleton

# For MySQL remember to first do from a MySQL shell:
# CREATE database skeleton;
# GRANT ALL ON skeleton.* TO 'skeleton'@'localhost' IDENTIFIED BY 'skeleton';
# FLUSH PRIVILEGES;

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': 'skeleton.db', # Or path to database file if using sqlite3.
        'USER': 'skeleton', # Not used with sqlite3.
        'PASSWORD': 'skeleton', # Not used with sqlite3.
        'HOST': '', # Set to empty string for localhost. Not used with sqlite3.
        'PORT': '', # Set to empty string for default. Not used with sqlite3.
    }
}

# Local time zone for this installation. Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# If running in a Windows environment this must be set to the same as your
# system time zone.
TIME_ZONE = 'UTC'
USE_TZ = True

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'en-us'

SITE_ID = 1

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = True

# Absolute path to the directory that holds media.
# Example: "/home/media/media.lawrence.com/"
MEDIA_ROOT = abspath("skeleton-media")

# URL that handles the media served from MEDIA_ROOT. Make sure to use a
# trailing slash if there is a path component (optional in other cases).
# Examples: "http://media.lawrence.com", "http://example.com/media/"
MEDIA_URL = '/media/'

STATIC_ROOT = abspath("static")

STATIC_URL = '/static/'

# URL prefix for admin media -- CSS, JavaScript and images. Make sure to use a
# trailing slash.
ADMIN_MEDIA_PREFIX = '/static/admin/'

# Make this unique, and don't share it with anybody.
SECRET_KEY = 'SECRET_KEY_PLACEHOLDER'

MIDDLEWARE_CLASSES = (
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'foundry.middleware.CheckProfileCompleteness',
    'django.contrib.messages.middleware.MessageMiddleware',
    'likes.middleware.SecretBallotUserIpUseragentMiddleware',
    'foundry.middleware.PaginationMiddleware',
    'django.contrib.flatpages.middleware.FlatpageFallbackMiddleware',
)

# A tuple of callables that are used to populate the context in RequestContext.
# These callables take a request object as their argument and return a
# dictionary of items to be merged into the context.
TEMPLATE_CONTEXT_PROCESSORS = (
    "django.contrib.auth.context_processors.auth",
    "django.contrib.messages.context_processors.messages",
    "django.core.context_processors.debug",
    "django.core.context_processors.i18n",
    "django.core.context_processors.media",
    "django.core.context_processors.static",
    "django.core.context_processors.request",
    'preferences.context_processors.preferences_cp',
    'foundry.context_processors.foundry',
)

TEMPLATE_LOADERS = (
    'layers.loaders.filesystem.Loader',
    'django.template.loaders.filesystem.Loader',
    'layers.loaders.app_directories.Loader',
    'django.template.loaders.app_directories.Loader',
)

ROOT_URLCONF = 'project.urls'

INSTALLED_APPS = (
    # The order is important else template resolution may not work
    'skeleton',
    'foundry',

    # Optional praekelt-maintained apps. Uncomment for development and
    # install with buildout or pip.
    #'banner',
    #'chart',
    #'competition',
    #'downloads',
    #'friends',
    #'gallery',
    #'jmbo_calendar',   # requires atlas
    #'jmbo_sitemap',
    #'jmbo_twitter',
    #'music',
    #'poll',
    #'show',            # requires jmbo_calendar

    # Minimal set of apps required by Jmbo
    'contact',
    'post',
    'jmbo_analytics',
    'jmbo',
    'category',
    'likes',
    'photologue',
    'secretballot',

    #'atlas',   # disabled by default because database support is hard
    'captcha',
    'ckeditor',
    'compressor',
    'dfp',
    'export',
    'generate',
    'googlesearch',
    #'grappelli.dashboard', # uncomment if you have a custom dashboard
    # 'grappelli',          # unresolved issues with foundry, so wait on grappelli
    'gunicorn',
    'object_tools',
    'pagination',
    'publisher',
    'preferences',
    'simple_autocomplete',
    'sites_groups',
    'snippetscream',
    'social_auth',
    'south',
    'tastypie',

    'django.contrib.auth',
    'django.contrib.comments',
    'django.contrib.contenttypes',
    'django.contrib.flatpages',
    'django.contrib.humanize',
    'django.contrib.sessions',
    'django.contrib.sites',
    'django.contrib.staticfiles',
    #'django.contrib.gis',   # disabled by default until spatialite is easily installable
    'django.contrib.sitemaps',
    'django.contrib.admin',

    'djcelery',
    'layers',
    'raven.contrib.django',
    'raven.contrib.django.celery',
#    'debug_toolbar',

)

# Your ReCaptcha provided public key.
RECAPTCHA_PUBLIC_KEY = '6LccPr4SAAAAAJRDO8gKDYw2QodyRiRLdqBhrs0n'

# Your ReCaptcha provided private key.
RECAPTCHA_PRIVATE_KEY = '6LccPr4SAAAAAH5q006QCoql-RRrRs1TFCpoaOcw'

# Module containing gizmo configuration
ROOT_GIZMOCONF = '%s.gizmos' % PROJECT_MODULE

# URL prefix for ckeditor JS and CSS media (not uploaded media). Make sure to use a trailing slash.
CKEDITOR_MEDIA_PREFIX = '/media/ckeditor/'

# Specify absolute path to your ckeditor media upload directory.
# Make sure you have write permissions for the path, i.e/home/media/media.lawrence.com/uploads/
CKEDITOR_UPLOAD_PATH = os.path.join(MEDIA_ROOT, "uploads")

CKEDITOR_CONFIGS = {
    'default': {'toolbar_Full': [
        ['Styles', 'Format', 'Bold', 'Italic', 'Underline', 'Strike', 'SpellChecker', 'Undo', 'Redo'],
        ['Link', 'Image', 'Flash', 'PageBreak'],
        ['TextColor', 'BGColor'],
        ['Smiley', 'SpecialChar'], ['Source'],
    ]},
}

# Restrict uploaded file access to user who uploaded file
CKEDITOR_RESTRICT_BY_USER = True

# LASTFM_API_KEY = '' # not used yet

LOGIN_URL = '/login'

LOGIN_REDIRECT_URL = '/'

AUTHENTICATION_BACKENDS = (
    'foundry.backends.MultiBackend',
    'django.contrib.auth.backends.ModelBackend',
    'social_auth.backends.facebook.FacebookBackend',
    'social_auth.backends.twitter.TwitterBackend',
)

COMMENTS_APP = 'foundry'

SIMPLE_AUTOCOMPLETE = {
    'auth.user': {'threshold': 20, 'search_field': 'username'},
    'category.category': {'threshold':20},
    'jmbo.modelbase': {
        'threshold': 50,
        'duplicate_format_function': lambda item, model, content_type: item.as_leaf_class().content_type.name
    }
}

STATICFILES_FINDERS = (
    'layers.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'layers.finders.AppDirectoriesFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
    'compressor.finders.CompressorFinder',
)

ADMIN_APPS_EXCLUDE = (
    'Cal',
    'Event',
    'Photologue',
    'Publisher',
    'Registration',
    'Auth',
)

ADMIN_MODELS_EXCLUDE = (
    'Groups',
    'Video files',
)

JMBO_ANALYTICS = {
    'google_analytics_id': 'xxx',
}

PHOTOLOGUE_MAXBLOCK = 2 ** 20

DJANGO_ATLAS = {
    'google_maps_api_key': 'AIzaSyBvdwGsAn2h6tNI75M5cAcryln7rrTYqkk',
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'filters': {
         'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse',
         }
     },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
    },
    'handlers': {
        'console': {
            'level': 'WARN',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
        'sentry': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'raven.contrib.django.handlers.SentryHandler',
        },
    },
    'loggers': {
        'raven': {
            'level': 'ERROR',
            'handlers': ['console'],
            'propagate': True,
        },
        'sentry.errors': {
            'level': 'ERROR',
            'handlers': ['console'],
            'propagate': True,
        },
        'django': {
            'handlers': ['console'],
            'level': 'WARN',
            'propagate': False,
        },
    },
}

# See django-socialauth project for all settings
SOCIAL_AUTH_USER_MODEL = 'foundry.Member'
#FACEBOOK_APP_ID = ''
#FACEBOOK_API_SECRET = ''
#TWITTER_CONSUMER_KEY = ''
#TWITTER_CONSUMER_SECRET = ''

SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'
COMPRESS_CSS_HASHING_METHOD = 'content'

# Set else async logging to Sentry does not work
CELERY_QUEUES = {
    'default': {
        'exchange': 'celery',
        'binding_key': 'celery'
    },
    'sentry': {
        'exchange': 'celery',
        'binding_key': 'sentry'
    },
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.dummy.DummyCache',
    }
}

BROKER_URL = 'redis://127.0.0.1:6379/0'
CELERY_RESULT_BACKEND = 'redis://127.0.0.1:6379/0'

# Debug toolbar. Uncomment if required.
#INSTALLED_APPS += ('debug_toolbar',)
#MIDDLEWARE_CLASSES += ('debug_toolbar.middleware.DebugToolbarMiddleware',)
#INTERNAL_IPS = ('127.0.0.1',)

import djcelery
djcelery.setup_loader()
