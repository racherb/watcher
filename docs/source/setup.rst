Quick Instalation
=================

There are several ways to install **Watcher** on your server. 
Choose the option that suits you best and go ahead!

From Docker
------------

Get **Watcher** container from a docker image:

.. code-block:: shell
   :linenos:

   docker pull racherb/watcher:latest
   docker run -i -t racherb/watcher

.. note::

  **Use docker volumes**. If you want to look at the host or remote machine's file system 
  then start a container with a ``volume``.

  The following example enables a volume on the temporary folder ``/tmp`` of the host 
  at path ``/opt/watcher/host/`` of the container.

  ``docker run -i -t -v /tmp/:/opt/watcher/host/tmp racherb/watcher``

From DEB Package
----------------

Quick installation from DEB Package:

.. code-block:: console
   :linenos:

   curl -s https://packagecloud.io/install/repositories/iamio/watcher/script.deb.sh | sudo bash
   sudo apt-get install watcher

.. note::
    
    *DEB Quick install* is available for the following distributions:

    * **Debian**: ``Lenny``, ``Trixie``, ``Bookworm``, ``Bullseye``, ``Buster``, ``Stretch``, ``Jessie``.
    * **Ubuntu**: ``Cosmic``, ``Disco``, ``Hirsute``, ``Groovy``, ``Focal``.
    * **ElementaryOS**: ``Freya``, ``Loki``, ``Juno``, ``Hera``.

From RPM Package
----------------

First install the repository:

.. code-block:: console

   curl -s https://packagecloud.io/install/repositories/iamio/watcher/script.rpm.sh | sudo bash

And install the package:

* For **RHEL** and **Fedora** distros: ``sudo yum install watcher-0.2.1-1.noarch``.
* For **Opensuse** and **Suse Linux Enterprise**: ``sudo zypper install watcher-0.2.1-1.noarch``.

.. note::

    *RPM Quick install* is available for the following distributions:

    * **RHEL**: ``7``, ``6``, ``8``.
    * **Fedora**: ``29``, ``30``, ``31``, ``32``, ``33``.
    * **OpenSuse**: ``15.1``, ``15.2``, ``15.3``, ``42.1``, ``42.2``, ``42.3``.
    * **Suse Linux Enterprise**: ``12.4``, ``12.5``, ``15.0``, ``15.1``, ``15.2``, ``15.3``.

From Tarantool
--------------

Quick installation from **Utility Tarantool**:

Install watcher through Tarantool's ``tarantoolctl`` command:

.. code-block:: console
   :linenos:
   
   tarantoolctl rocks install avro-schema
   tarantoolctl rocks install https://raw.githubusercontent.com/racherb/watcher/master/watcher-scm-1.rockspec

From LuaRocks
-------------

Make sure you have Luarocks installed first.

From the ``terminal`` run the following command:

.. code-block:: console

   luarocks install https://raw.githubusercontent.com/racherb/watcher/master/watcher-scm-1.rockspec

