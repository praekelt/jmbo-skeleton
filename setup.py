from setuptools import setup, find_packages

setup(
    name='jmbo-skeleton',
    version='2.0.0',
    description='Create a Jmbo project environment quickly. Includes a Jmbo demo application.',
    long_description = open('README.rst', 'r').read() + open('AUTHORS.rst', 'r').read() + open('CHANGELOG.rst', 'r').read(),
    author='Praekelt Consulting',
    author_email='dev@praekelt.com',
    license='BSD',
    url='',
    packages = find_packages(),
    install_requires = [
        'jmbo-foundry>=2.0.3',
        'django_compressor',
        'django-debug-toolbar',
        'django-grappelli<2.6',
        'gunicorn',
        'raven',
    ],
    include_package_data=True,
    tests_require=[
        'django-setuptest>=0.1.6',
    ],
    test_suite="setuptest.setuptest.SetupTestSuite",
    classifiers=[
        "Programming Language :: Python",
        "License :: OSI Approved :: BSD License",
        "Development Status :: 4 - Beta",
        "Operating System :: OS Independent",
        "Framework :: Django",
        "Intended Audience :: Developers",
        "Topic :: Internet :: WWW/HTTP :: Dynamic Content",
    ],
    zip_safe=False,
)
