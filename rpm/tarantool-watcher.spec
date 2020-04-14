Name: tarantool-watcher
Version: 2.0.0
Release: 1%{?dist}
Summary: Lua module template for Tarantool
Group: Applications/Databases
License: BSD
URL: https://github.com/tarantool/modulekit
Source0: watcher-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool-devel >= 1.6.8.0
Requires: tarantool >= 1.6.8.0

%description
This package provides a Lua module template for Tarantool.

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
* Tue Feb 21 2017 Roman Tsisyk <roman@taratoool.org> 2.0.0-1
- Split package into watcher and ckit.

* Wed Feb 17 2016 Roman Tsisyk <roman@tarantool.org> 1.0.1-1
- Fix to comply Fedora Package Guidelines

* Wed Sep 16 2015 Roman Tsisyk <roman@tarantool.org> 1.0.0-1
- Initial version of the RPM spec
