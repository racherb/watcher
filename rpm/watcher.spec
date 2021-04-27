Name: watcher
Version: 0.2.1-1
Release: 1%{?dist}
Summary: Watcher for watches the changes in the file system, variables and data records.
Group: Applications/Databases
License: BSD
URL: https://github.com/racherb/watcher
Source0: watcher-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool >= 1.7
BuildRequires: tarantool-devel >= 1.7
BuildRequires: /usr/bin/prove
Requires: tarantool >= 1.7

%description
Watcher for watches the changes in the file system, variables and data records.

%prep
%setup -q -n watcher-%{version}

%check
./test/watcher.test.lua

%install
# Create /usr/share/watcher
mkdir -p %{buildroot}%{_datadir}/watcher
# Copy init.lua to /usr/share/tarantool/watcher/init.lua
cp -p src/*.lua %{buildroot}%{_datadir}/watcher

%files
%dir %{_datadir}/watcher
%{_datadir}/watcher/
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE AUTHORS

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
