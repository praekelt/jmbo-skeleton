from django.core import management
from django.utils import unittest
from django.test.client import Client as BaseClient, FakePayload, \
    RequestFactory
from django.core.urlresolvers import reverse

from post.models import Post
from foundry.models import Member


class Client(BaseClient):
    """Bug in django/test/client.py omits wsgi.input"""

    def _base_environ(self, **request):
        result = super(Client, self)._base_environ(**request)
        result['HTTP_USER_AGENT'] = 'Django Unittest'
        result['HTTP_REFERER'] = 'dummy'
        result['wsgi.input'] = FakePayload('')
        return result


class TestCase(unittest.TestCase):

    @classmethod  
    def setUpClass(cls):
        cls.request = RequestFactory()
        cls.client = Client()

        # Post-syncdb steps
        management.call_command('migrate', interactive=False)
        management.call_command('load_photosizes', interactive=False)
        management.call_command('loaddata', 'skeleton/fixtures/sites.json', interactive=False)

        # Editor
        cls.editor, dc = Member.objects.get_or_create(
            username='editor',
            email='editor@test.com'
        )
        cls.editor.set_password("password")
        cls.editor.save()
        
        # Post
        post, dc = Post.objects.get_or_create(
            title='Post 1', content='<b>aaa</b>',
            owner=cls.editor, state='published',
        )
        post.sites = [1]
        post.save()

    def test_common_urls(self):
        """High-level test to confirm common set of URLs render"""
        urls = (
            (reverse('join'), 200),
            (reverse('login'), 200),
            (reverse('logout'), 302),
            (reverse('password_reset'), 200),
            (reverse('terms-and-conditions'), 200), 
            ('/post/post-1/', 200),
        )
        for url, code in urls:
            print "Checking path %s" % url
            response = self.client.get(url)
            self.assertEqual(response.status_code, code)
