Watcher features
=================

The **Watcher** module has been designed with the typical use cases of the Banking 
and Telecommunications industry in mind for *IT Batch Processing*.

If you know of a use case that is not covered by watcher, 
please tell us about it in the 
`GitHub Discussions Section <https://github.com/racherb/watcher/discussions/categories/ideas/>`_ .

Currently **Watcher** comprises the following features: 
:ref:`Single File & Folders`, 
:ref:`Multiples File Groups`,
:ref:`File Patterns`,
:ref:`Non-Bloking Execution`, 
:ref:`Bloking Execution`,, 
Bulk File Processing, 
Advanced File Deletion, 
Advanced File Creation, 
Advanced File Alteration, 
Watcher for Any Alteration, Watcher for Specific Alteration, Decoupled Execution,
Novelty Detection, Qualitative Response, Check File Stability, Big Amounts of Files,
Atomic Function Injection, Folder Recursion, Selective Path Level, Watcher Monitoring
, ...


.. note::
   The lines of code used to exemplify each feature of watcher assume the following: 
   ``fwa = require('watcher').file``.

.. _Single File & Folders:

Single File & Folders
----------------------

Detection of ``creation``, ``deletion`` and ``alteration`` of **single files** or **single folders** in the file system.

.. code-block:: lua
   :linenos:

   fwa.creation({'/path/to/single_file'})
   fwa.creation({'/path/to/single_folder/'})

.. _Multiples File Groups:

Multiples File Groups
---------------------

Multiple groups of different files can be watched at the same time.
The input list of watchable files is a Lua table type parameter.

.. code-block:: lua
   :linenos:
   :emphasize-lines: 3,4

   fwa.deletion(
       {
           '/path1/to/group_file_a/*',
           '/path2/to/group_file_b/*'
        }
    )

.. _File Patterns:

File Patterns
--------------

.. code-block:: lua

   fwa.creation({'/path/to/files_*.txt'})

.. note::
   The *watch-list* is constructed with a single flag that controls the behavior of the function: **GLOB_NOESCAPE**. 
   For details type ``man 3 glob``.

.. _Non-Bloking Execution:

Non-Bloking Execution
---------------------

By default the **Watcher** run is executed in non-blocking mode through tarantool fibers. 
Fibers are a unique Tarantool feature *"green threads"* or coroutines that run independently 
of operating system threads.

.. _Bloking Execution:

Blocking Execution
------------------

The ``waitfor`` function blocks the code and waits for a watcher to finish.

.. code-block:: lua

   waitfor(fwa.creation({'/path/to/file'}).wid)


Bulk File Processing
--------------------

**Watcher** has an internal mechanism to allocate fibers for every certain amount of files 
in the watcher list. This amount is determined by the ``BULK_CAPACITY`` configuration value 
in order to optimize performance.

Advanced File Deletion
----------------------

Inputs
******

.. list-table:: File Watcher Deletion Parameters
   :widths: 25 25 50
   :header-rows: 1

   * - Param
     - Type
     - Description
   * - wlist
     - ``table``, ``required``
     - Watch List
   * - maxwait
     - ``number``, ``otional``, ``default-value: 60``
     - Maximum wait time in seconds
   * - interval
     - ``number``, ``otional``, ``default-value: 0.5``
     - Verification interval for watcher in seconds
   * - options
     - ``table``, ``optional``, ``default-value: {'NS', 0, 0}``
     - List of search options

Options
*******

Advanced File Creation
----------------------

Inputs
******

.. list-table:: File Watcher Creation Parameters
   :widths: 25 25 50
   :header-rows: 1

   * - Param
     - Type
     - Description
   * - wlist
     - ``table``, ``required``
     - Watch List
   * - maxwait
     - ``number``, ``otional``, ``default-value: 60``
     - Maximum wait time in seconds
   * - interval
     - ``number``, ``otional``, ``default-value: 0.5``
     - Verification interval for watcher in seconds
   * - minsize
     - ``number``, ``optional``, ``default-value: 0``
     - Value of the minimum expected file size
   * - stability
     - ``table``, ``optional``, ``default-value: {1, 15}``
     - Minimum criteria for measuring file stability
   * - novelty
     - ``table``, ``optional``, ``default-value: {0, 0}``
     - Time interval that determines the validity of the file's novelty
   * - nmatch
     - ``number``, ``optional``, ``default-value: 0``
     - Number of expected files as a search sufficiency condition

minsize
*******

stability
*********

internal
iterations

novelty
*******

nmatch
******

Advanced File Alteration
------------------------

Inputs
******


.. list-table:: File Watcher Alteration Parameters
   :widths: 25 25 50
   :header-rows: 1

   * - Param
     - Type
     - Description
   * - wlist
     - ``table``, ``required``
     - Watch List
   * - maxwait
     - ``numeric``, ``otional``, ``default-value: 60``
     - Maximum wait time in seconds
   * - interval
     - ``numeric``, ``otional``, ``default-value: 0.5``
     - Verification interval for watcher in seconds
   * - awhat
     - ``string``, ``optional``, ``default-value: '1'``
     - Type of file alteration to be observed
   * - nmatch
     - ``number``, ``optional``, ``default-value: 0``
     - Number of expected files as a search sufficiency condition

awhat
*****

.. list-table:: File Watcher Alteration Parameters
   :widths: 25 10 65
   :header-rows: 1

   * - Type
     - Value
     - Description
   * - ``ANY_ALTERATION``
     - ``'1'``
     - Search for any alteration
   * - ``CONTENT_ALTERATION``
     - ``'2'``
     - Search for content file alteration
   * - ``SIZE_ALTERATION``
     - ``'3'``
     - Search for file size alteration
   * - ``CHANGE_TIME_ALTERATION``
     - ``'4'``
     - Search for file ``ctime`` alteration
   * - ``MODIFICATION_TIME_ALTERATION``
     - ``'5'``
     - Search for file ``mtime`` alteration
   * - ``INODE_ALTERATION``
     - ``'6'``
     - Search for file ``inode`` alteration
   * - ``OWNER_ALTERATION``
     - ``'7'``
     - Search for file ``owner`` alteration
   * - ``GROUP_ALTERATION``
     - ``'8'``
     - Search for file ``group`` alteration

Watcher for Any Alteration
---------------------------

.. code-block:: lua

   fwa.alteration({'/path/to/file'}, nil, nil, '1')

Watcher for Specific Alteration
-------------------------------

.. code-block:: lua
   :linenos:

   fwa.alteration({'/path/to/file'}, nil, nil, '2') --Watcher for content file alteration
   fwa.alteration({'/path/to/file'}, nil, nil, '3') --Watcher for content file size alteration
   fwa.alteration({'/path/to/file'}, nil, nil, '4') --Watcher for content file ctime alteration

See table "*File Watcher Alteration Parameters*" for more options.
   

Decoupled Execution
-------------------

The ``create``, ``runv functions and the ``monit`` options have been decoupled 
for better behavior, overhead relief and versatility of use.

Novelty Detection
------------------


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