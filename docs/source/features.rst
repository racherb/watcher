Watcher features
=================

The **Watcher** module has been designed with the typical use cases of the Banking 
and Telecommunications industry in mind for *IT Batch Processing*.

.. note::
   The lines of code used to exemplify each feature of watcher assume the following: 
   ``fwa = require('watcher').file``.

Single File & Folders
----------------------

Detection of ``creation``, ``deletion`` and ``alteration`` of **single files** or **single folders** in the file system.

.. code-block:: lua
   :linenos:

   fwa.creation({'/path/to/single_file'})
   fwa.creation({'/path/to/single_folder/'})

Multiples File Groups
---------------------

Multiple groups of different files can be watched at the same time.
The input list of watchable files is a Lua table type parameter.

.. code-block:: lua
   :linenos:

   fwa.deletion(
       {
           '/path1/to/group_file_a/*',
           '/path2/to/group_file_b/*'
        }
    )

File Patterns
--------------

.. code-block:: lua

   fwa.creation({'/path/to/files_*.txt'})

.. note::
   The *watch-list* is constructed with a single flag that controls the behavior of the function: **GLOB_NOESCAPE**. 
   For details type ``man 3 glob``.

Non-Bloking Execution
---------------------

By default the **Watcher** run is executed in non-blocking mode through tarantool fibers. 
Fibers are a unique Tarantool feature *"green threads"* or coroutines that run independently 
of operating system threads.

Blocking Execution
------------------

The ``waitfor`` function blocks the code and waits for a watcher to finish.

.. code-block:: lua

   waitfor(fwa.creation('/path/to/file').wid)


Bulk File Processing
--------------------

..


Advanced File Deletion
----------------------

Advanced File Creation
----------------------

Advanced File Alteration
------------------------


Decoupled Execution
-------------------

Novelty Detection
------------------

Watcher for Any Alteration
---------------------------

Watcher for Specific Alteration
-------------------------------


Qualitative Response
--------------------


Check File Stability
--------------------

Big Amounts of Files
--------------------


Atomic Function Injection
-------------------------

Atomic function injection allows you
to perform specific tasks on each element of the watchable list separately.
In the example, the atomic function afu creates a backup copy for each element of the watchlist.

.. code-block:: lua
   :linenos:

   afu = function(file) os.execute('cp '..file..' '..file..'_backup') end --Atomic Funcion
   cor = require('watcher').core
   wat = cor.create({'/tmp/original.txt'}, 'FWD', afu) --afu is passed as parameter
   res = run_watcher(wat)

Folder Recursion
----------------



Selective Path Level
--------------------


Watcher Monitoring
------------------


- [x] Watcher for different file groups
- [x] Watcher for file naming patterns
- [x] Watcher for Advanced File Deletion
- [x] Watcher for Advanced File Creation
- [x] Watcher for Advanced File Alteration
- [x] Non-blocking execution with tarantool fibers
- [x] Bulk file processing
- [x] :new: Blocking execution with "*waitfor*" function
- [x] :new: Decoupled execution between the creation of the watcher and its execution
- [x] Discrimination of files by sorting and quantity
- [x] Novelty detection for file creation
- [x] Watcher for any changes or alteration in the file system
- [x] Watcher for specific changes in the file system
- [x] Qualitative response for each observed file
- [x] Processing of large quantities of files
- [x] Validation of the stability of the file when it is created
- [x] Configuration of the file watcher conditions
- [x] Validation of the minimum expected size of a file
- [x] Detection of anomalies in the observation of the file
- [x] :new: Injection of atomic functions on the watcher list
- [x] :new: Folder recursion and selective path level
- [x] :new: Watcher monitoring (info, match, nomatch)