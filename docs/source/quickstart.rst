Quick Start
===========

Detection of ``creation``, ``deletion`` and ``alteration`` of **single files** or **single folders** in the file system.

.. code-block:: lua
   :linenos:

   fwa = require('watcher').file               --for file-watcher
   fwa.creation({'/path/to/single_file'})      --watching file creation
   fwa.deletion({'/path/to/single_folder/'})   --watching folder deletion
   fwa.alteration('/path/to/single_folder/*')  --watching file alteration

