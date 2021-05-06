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
:ref:`Bloking Execution`,
:ref:`Bulk File Processing`, 
:ref:`Advanced File Deletion`, 
:ref:`Advanced File Creation`, 
:ref:`Advanced File Alteration`, 
:ref:`Watcher for Any Alteration`,
:ref:`Watcher for Specific Alteration`,
:ref:`Decoupled Execution`,
:ref:`Novelty Detection`,
:ref:`Qualitative Response`,
:ref:`Check File Stability`,
:ref:`Big Amounts of Files`,
:ref:`Atomic Function Injection`,
:ref:`Folder Recursion`,
:ref:`Selective Path Level`,
:ref:`Watcher Monitoring`

.. note::
   The lines of code used to exemplify each feature of watcher assume the following: 

   .. code-block:: lua
      :linenos:
      
      fwa = require('watcher').file   --for file-watcher
      mon = require('watcher').monit  --for watcher monitoring

.. _Single File & Folders:

Single File & Folders
----------------------

Detection of ``creation``, ``deletion`` and ``alteration`` of **single files** or **single folders** in the file system.

.. code-block:: lua
   :linenos:

   fwa.creation({'/path/to/single_file'})    --watching file creation
   fwa.creation({'/path/to/single_folder/'}) --watching folder creation

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
           '/path_1/to/group_file_a/*',  --folder
           '/path_2/to/group_file_b/*'   --another
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

   waitfor(fwa.creation({'/path/to/file'}).wid) --wait for watcher

.. _Bulk File Processing:

Bulk File Processing
--------------------

**Watcher** has an internal mechanism to allocate fibers for every certain amount of files 
in the watcher list. This amount is determined by the ``BULK_CAPACITY`` configuration value 
in order to optimize performance.

.. _Advanced File Deletion:

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

wlist
*****

It is the list of files, directories or file patterns to be observed. The data type is a Lua table and 
the size of tables is already limited to ``2.147.483.647`` elements.

An example definition is the following:

.. code-block:: lua
   
   wlist = {'path/file', 'path', 'pattern*', ...} --arbitrary code

maxwait
*******

Maxwait is a numeric value that represents the maximum time to wait for the watcher. 
Watcher will terminate as soon as possible and as long as the search conditions are met. 
The default value is ``60 seconds``. 

interval
********

Interval is a numerical value that determines how often the watcher checks the search conditions. 
This value must be less than the maxwait value. 
The default value is ``0.5`` seconds.

options
*******
The options parameter is a Lua table containing 3 elements: ``sort``, ``cases`` and ``match``.

* The first one ``sort`` contains the ordering method of the ``wlist``. 
* The second element ``cases`` contains the number of cases to observe from the wlist.
* and the third element ``match`` indicates the number of cases expected to satisfy the search. 

By default, the value of the option table is ``{sort = 'NS', cases = 0, match = 0}``.

.. list-table:: The list of possible values for ``sort``
   :widths: 12 50
   :header-rows: 1

   * - Value
     - Description
   * - ``'NS'``
     - No sort
   * - ``'AA'``
     - Sorted alphabetically ascending
   * - ``'AD'``
     - Sorted alphabetically descending
   * - ``'MA'``
     - Sorted by date of modification ascending
   * - ``'MD'``
     - Sorted for date of modification descending

.. note::

   The value ``'NS'`` treats the list in the same order in which the elements 
   are passed to the list ``wlist``.


Output
******

.. _Advanced File Creation:

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

wlist
*****

It is the list of files, directories or file patterns to be observed. The data type is a Lua table and 
the size of tables is already limited to ``2.147.483.647`` elements.

An example definition is the following:

.. code-block:: lua
   
   wlist = {'path/file', 'path', 'pattern*', ...} --arbitrary code

maxwait
*******

Maxwait is a numeric value that represents the maximum time to wait for the watcher. 
Watcher will terminate as soon as possible and as long as the search conditions are met. 
The default value is ``60 seconds``. 

interval
********

Interval is a numerical value that determines how often the watcher checks the search conditions. 
This value must be less than the maxwait value. 
The default value is ``0.5`` seconds.

minsize
*******

Minsize is a numerical value representing the minimum expected file size. 
The default value is ``0``, which means that it is sufficient to just generate the file when the minimum size is unknown.

.. important::

   Regardless of whether the expected file size is ``0 Bytes``, 
   watcher will not terminate until the file arrives in its entirety, 
   avoiding edge cases where a file is consumed before the data transfer is complete.

.. _stability:

stability
*********

The ``stability`` parameter contains the elements that allow to evaluate the stability of a file. 
It is a Lua table containing two elements:

* The ``interval`` that defines the frequency of checking the file once it has arrived.
* The number of ``iterations`` used to determine the stability of the file.

The default value is: ``{1, 15}``.

novelty
*******

The ``novelty`` parameter is a two-element Lua table that contains the 
time interval that determines the validity of the file’s novelty.
The default value is ``{0, 0}`` which indicates that the novelty of the file will not be evaluated.

nmatch
******

``nmatch`` is a number of expected files as a search sufficiency condition.

.. _Advanced File Alteration:

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

wlist
*****

It is the list of files, directories or file patterns to be observed. The data type is a Lua table and 
the size of tables is already limited to ``2.147.483.647`` elements.

An example definition is the following:

.. code-block:: lua
   
   wlist = {'path/file', 'path', 'pattern*', ...} --arbitrary code

maxwait
*******

Maxwait is a numeric value that represents the maximum time to wait for the watcher. 
Watcher will terminate as soon as possible and as long as the search conditions are met. 
The default value is ``60 seconds``. 

interval
********

Interval is a numerical value that determines how often the watcher checks the search conditions. 
This value must be less than the maxwait value. 
The default value is ``0.5`` seconds.

awhat
*****

Type of file alteration to be observed. See :ref:`File Watcher Alteration Parameters`.

.. _File Watcher Alteration Parameters:

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

nmatch
******

``nmatch`` is a number of expected files as a search sufficiency condition.

.. _Watcher for Any Alteration:

Watcher for Any Alteration
---------------------------

.. code-block:: lua

   fwa.alteration({'/path/to/file'}, nil, nil, '1')

.. _Watcher for Specific Alteration:

Watcher for Specific Alteration
-------------------------------

.. code-block:: lua
   :linenos:

   fwa.alteration({'/path/to/file'}, nil, nil, '2') --Watcher for content file alteration
   fwa.alteration({'/path/to/file'}, nil, nil, '3') --Watcher for content file size alteration
   fwa.alteration({'/path/to/file'}, nil, nil, '4') --Watcher for content file ctime alteration
   --explore other options for 'awhat' values

See table :ref:`File Watcher Alteration Parameters` for more options.
   
.. _Decoupled Execution:

Decoupled Execution
-------------------

The ``create``, ``run`` function and the ``monit`` options have been decoupled 
for better behavior, overhead relief and versatility of use.

.. _Novelty Detection:

Novelty Detection
------------------

**Watcher** implements the detection of the newness of a file based on the ``mtime`` modification date. 
This is useful to know if file system items have been created in an expected time window.

.. warning::

   Note that the creation of the files may have been done preserving the attributes of the original file. 
   In that case you should consider the novelty rank accordingly.

.. _Qualitative Response:

Qualitative Response
--------------------

Watcher leaves a record for each watchable file where it provides qualitative 
nformation about the search result for each of them. 
To explore this information see the :ref:`Watcher Monitoring` ``match`` and ``nomatch`` functions.

.. code-block:: lua
   :linenos:

    NOT_YET_CREATED = '_'               --The file has not yet been created
    FILE_PATTERN = 'P'                  --This is a file pattern
    HAS_BEEN_CREATED = 'C'              --The file has been created
    IS_NOT_NOVELTY = 'N'                --The file is not an expected novelty
    UNSTABLE_SIZE = 'U'                 --The file has an unstable file size
    UNEXPECTED_SIZE = 'S'               --The file size is unexpected
    DISAPPEARED_UNEXPECTEDLY = 'D'      --The file has disappeared unexpectedly
    DELETED = 'X'                       --The file has been deleted
    NOT_EXISTS = 'T'                    --The file does not exist
    NOT_YET_DELETED = 'E'               --The file has not been deleted yet
    NO_ALTERATION = '0'                 --The file has not been modified
    ANY_ALTERATION = '1'                --The file has been modified
    CONTENT_ALTERATION = '2'            --The content of the file has been altered
    SIZE_ALTERATION = '3'               --The file size has been altered
    CHANGE_TIME_ALTERATION = '4'        --The ctime of the file has been altered
    MODIFICATION_TIME_ALTERATION = '5'  --The mtime of the file has been altered
    INODE_ALTERATION = '6'              --The number of inodes has been altered
    OWNER_ALTERATION = '7'              --The owner of the file has changed
    GROUP_ALTERATION = '8'              --The group of the file has changed

.. _Check File Stability:

Check File Stability
--------------------

Enabled only for file creation. 
This feature ensures that the **watcher** terminates once the file creation is completely finished. 
This criterion is independent of the file size.

See usage for parameter :ref:`stability`

.. _Big Amounts of Files:

Big Amounts of Files
--------------------

.. _Atomic Function Injection:

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

.. _Folder Recursion:

Folder Recursion
----------------

.. _Selective Path Level:

Selective Path Level
--------------------

.. _Watcher Monitoring:

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