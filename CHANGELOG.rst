Changelog
=========

next
----
#. Webdav access now enabled. It is useful for changing CSS on QA sites on the fly.
#. Webdav requires we backup static resources on each deploy. Added to deploy_project.sh.
#. Removed Praekelt assumption from deploy script.
#. Up required jmbo-foundry to 0.6. Django 1.4 is now implicitly required.

0.4
---
#. Up minimum jmbo-foundry to 0.5.
#. Create a trivial south migration so order of migrations is correct.

0.3.2
-----
#. Dev buildout now uses git instead of https.

0.3.1
-----
#. Remove flup since it is currently broken. 
#. Create different sites for mobi and web.

0.3
---
#. Templates for mid and smart layers.
#. Server setup bug fixes.

0.2.4
-----
#. Fix manifest and up minimum jmbo-foundry to 0.4.

0.2.2
-----
#. Fix typos.

0.2.1
-----
#. Change egg name to jmbo-skeleton.

0.1
---
#. Initial release

