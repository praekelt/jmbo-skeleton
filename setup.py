from setuptools import setup, find_packages

setup(
    name='jmbo-skeleton',
    version='0.5',
    description='Create a Jmbo project environment quickly. Includes a Jmbo demo application.',
    long_description = open('README.rst', 'r').read() + open('AUTHORS.rst', 'r').read() + open('CHANGELOG.rst', 'r').read(),
    author='Praekelt Foundation',
    author_email='dev@praekelt.com',
    license='BSD',
    url='',
    packages = find_packages(),
    install_requires = [
        'jmbo-foundry>=1.0',
    ],
    include_package_data=True,
    tests_require=[
        'django-setuptest>=0.1.2',
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
