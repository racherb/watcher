Name: watcher
Version: %{version}
Release: 1%{?dist}
Summary: Watches the changes
Group: Applications/Databases
License: BSD
URL: https://github.com/racherb/watcher
Source0: https://github.com/racherb/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool >= 1.7
BuildRequires: tarantool-devel >= 1.7
BuildRequires: /usr/bin/prove
Requires: tarantool >= 1.7

%description
Watches the changes in the file system, variables and data records

%prep
%setup -q -n watcher-%{version}

%check
./test/watcher.test.lua

%install
# Create /usr/share/watcher
mkdir -p %{buildroot}%{_datadir}/watcher
# Copy watcher.lua to /usr/share/watcher/watcher.lua
cp -p watcher/*.lua %{buildroot}%{_datadir}/watcher

%files
%dir %{_datadir}/watcher
%{_datadir}/watcher/
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE AUTHORS

%changelog
