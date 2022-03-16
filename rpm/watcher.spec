Name: watcher
Version: 0.2.3
Release: 1%{?dist}
Summary: Watcher for watches the changes in the file system, variables and data records
Group: Development/Libraries
License: BSD
URL: https://github.com/racherb/watcher
Source0: %{name}-%{version}.tar.gz
BuildArch: noarch
Requires: tarantool >= 1.7
BuildRoot: %{_topdir}/BUILDROOT/

%description
Watcher for watches the changes in the file system, variables and data records.

%define _binaries_in_noarch_packages_terminate_build   0

%prep
%setup -q

%autosetup

%check
#./test/watcher.test.lua

%build

%install
rm -rf %{buildroot}
install -m 0755 -d %{buildroot}/opt/%{name}
mkdir -p %{buildroot}/opt/%{name}/db
mkdir -p %{buildroot}/opt/%{name}/types
mkdir -p %{buildroot}/opt/%{name}/plugins
cp -a *.lua %{buildroot}/opt/%{name}
cp -p *.lua %{buildroot}/opt/%{name}
cp -p db/*.lua %{buildroot}/opt/%{name}/db/
cp -p types/*.lua %{buildroot}/opt/%{name}/types/
cp -p plugins/*.lua %{buildroot}/opt/%{name}/plugins
cp -p cli/watcher %{buildroot}/opt/%{name}/
mkdir -p %{buildroot}/opt/%{name}/.rocks/share/tarantool/avro_schema
mkdir -p %{buildroot}/opt/%{name}/.rocks/lib/tarantool
cp -p .rocks/share/tarantool/avro_schema/* %{buildroot}/opt/%{name}/.rocks/share/tarantool/avro_schema/
cp -p .rocks/lib/tarantool/avro_schema_rt_c.so %{buildroot}/opt/%{name}/.rocks/lib/tarantool/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/opt/%{name}/*.lua
/opt/%{name}/db/*
/opt/%{name}/types/*
/opt/%{name}/plugins/*
/opt/%{name}/.rocks/share/tarantool/avro_schema/*
/opt/%{name}/.rocks/lib/tarantool/avro_schema_rt_c.so
%{!?_licensedir:%global license %doc}
%license LICENSE

%changelog
* Tue Mar 15 2022 Raciel Hernandez <racherb@protonmail.com> v0.2.4-1-e6c5e8f
- Add stability check and other small changes
- Pass stability only if it comes as a parameter
- Add spinner for wait in to command line
- Add new test plan
- Add WATCHER_PATH
- Correction for bulk file deletion
- Correction for math when is zero
- Consolidate by watcher kind
- Unify wlist consolidate
- File name correction
- Convert ignore list to table
- Add ref to module watcher-cli

* Thu Feb 26 2022 Raciel Hernandez <racherb@protonmail.com> v0.2.3-12-ga58e484
- Fix issue #15 "Bad argument #1 to 'pairs' (table expected, got string)"
- Convert "ignore" string list input to table in command line interface.

* Thu Feb 25 2022 Raciel Hernandez <racherb@protonmail.com> v0.2.3-7-g2fa6164
- "ansicolors" dependency added

* Tue Feb 23 2022 Raciel Hernandez <racherb@protonmail.com> v0.2.3-0-g1277cb1
- Command line interface
- Non-color command line support according to no-color.org
- New functionality for naming watchers
- New functionality for watcher deletion
- New functionality "string2wlist" to convert a file list string to an internally used table type.
- The "sleep" functionality is exposed at the module level
- You can now ignore files from the list to be watched
- Functionalities "deduplicate" and "consolidate" are now exposed at module level
- The run watcher procedure can now receive a watcher parameter or by its watcher id
- Watcher status standardization
- Code refactoring and other small changes

* Wed May 12 2021 Raciel Hernandez <racherb@protonmail.com> v0.2.2-1-g0e40729
- Small code refactoring for better performance and issues fixed
- Fix issue #13 "close func not work for alteration when the file not exist #13"
- Fix issue #12 "Monit's nomatch always returns the additional number of elements that are search patterns. #12"

* Fri Apr 23 2021 Raciel Hernandez <racherb@protonmail.com> v0.2.1-1
- Fix tarantool-dev and libmsgpuck-dev dependencies
- Set correct Architecture
- Update Standards-Version
- Create watcher function
- Run watcher function
- Wait for watcher function
- Atomic functions over watchables
- Folder recursion
- Selective path level for recursion
- Watcher monitoring (info, match, nomatch)
- New tests are added
- Important code refactoring (file_deletion, file_creation, file_alteration)
- Fix issue #10 "LuajitError: builtin/fio.lua:544: pathname is absent #10"
- Refactoring watcher.test.lua

* Wed Apr 07 2021 Raciel Hernandez <racherb@protonmail.com> v0.1.1-172-gb7309a3
- Initial release
