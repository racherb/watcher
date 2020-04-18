Name: watcher
Version: 2.0.0
Release: 1%{?dist}
Summary: Watches the changes
Group: Applications/Databases
License: BSD
URL: https://github.com/racherb/watcher
Source0: watcher-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool-devel >= 1.6.8.0
Requires: tarantool >= 1.6.8.0

%description
Watches the changes in the file system, variables and data records

%prep
%setup -q -n watcher-%{version}

%check
./test/watcher.test.lua

%install
# Create /usr/share/watcher
mkdir -p %{buildroot}%{_datadir}/watcher
# Copy init.lua to /usr/share/watcher/init.lua
cp -p watcher/*.lua %{buildroot}%{_datadir}/watcher

%files
%dir %{_datadir}/watcher
%{_datadir}/watcher/
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE AUTHORS

%changelog
