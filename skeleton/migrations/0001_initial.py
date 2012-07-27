# -*- coding: utf-8 -*-
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models


class Migration(SchemaMigration):

    depends_on = (
        ("foundry", "0036_auto__add_field_listing_pinned"),
    )

    def forwards(self, orm):
        pass

    def backwards(self, orm):
        pass


    models = {
    }

    complete_apps = ['skeleton']
