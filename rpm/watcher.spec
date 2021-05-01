Name: watcher
Version: 0.2.1
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
