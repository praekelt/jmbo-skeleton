import os

from django.core.management.base import BaseCommand, CommandError

import foundry


class Command(BaseCommand):

    def handle(self, *args, **options):
        print os.path.join(*os.path.split(os.path.split(foundry.__file__)[0])[:-1])
