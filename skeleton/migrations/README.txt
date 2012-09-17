It is highly recommended to add a migration dependency on foundry. You must
manually add a setting `depends_on` to 0001_initial.py. You class header will
then look similar to this:

class Migration(SchemaMigration):

    depends_on = (
        ("foundry", "0036_auto__add_field_listing_pinned"),
    )

For absolute safety set the migration number (0036 in our example) to that of
the latest foundry migration.
