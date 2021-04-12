Name: tarantool-watcher
Version: 0.1.1
Release: 1%{?dist}
Summary: Watcher for watches the changes in the file system, variables and data records.
Group: Applications/Databases
License: BSD
URL: https://github.com/racherb/watcher
Source0: watcher-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool-devel >= 1.6.8.0
Requires: tarantool >= 1.6.8.0

%description
Watcher for watches the changes in the file system, variables and data records.

%prep
%setup -q -n watcher-%{version}

%check
./test/watcher.test.lua

%install
# Create /usr/share/tarantool/watcher
mkdir -p %{buildroot}%{_datadir}/tarantool/watcher
# Copy init.lua to /usr/share/tarantool/watcher/init.lua
cp -p watcher/*.lua %{buildroot}%{_datadir}/tarantool/watcher

%files
%dir %{_datadir}/tarantool/watcher
%{_datadir}/tarantool/watcher/
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE AUTHORS

%changelog
