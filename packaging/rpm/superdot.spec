# RPM package for Fedora and openSUSE. Can be published on Fedora COPR, which downloads
# Source0 from the GitHub release tag.
# Local build: spectool -g -R packaging/rpm/superdot.spec && rpmbuild -bb packaging/rpm/superdot.spec
# The GitHub release workflow builds it too, from a local tarball of the same name.
Name:           superdot
Version:        1.0.0
Release:        1%{?dist}
Summary:        Emoji for Linux: the Win+. emoji panel
License:        MIT AND Unicode-3.0
URL:            https://github.com/saikatnjm/superdot
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  pkgconfig(gtk+-3.0)
BuildRequires:  pkgconfig(x11)
BuildRequires:  systemd-rpm-macros
# GTK and X11 libraries are detected automatically from the binary (names differ per distro).
Requires:       python3
Requires:       python3-gobject
%if 0%{?suse_version}
Requires:       typelib(Gio)
Recommends:     google-noto-coloremoji-fonts
%else
Recommends:     google-noto-color-emoji-fonts
%endif
# libXtst is loaded at runtime when present (typing into X11 apps without /dev/uinput).
Recommends:     libXtst

%description
SuperDot brings the Windows emoji panel (Win+.) to Linux. Press Super+. in
any app, type to search, and pick an emoji, kaomoji or symbol: it is typed
where you were writing, and your clipboard is put back afterwards. Skin
tones, recently used, and only the emoji your fonts can draw. Works on GNOME,
KDE Plasma, Cinnamon, MATE and Xfce, on Wayland and X11. No network access.

%prep
%autosetup

%build
%make_build CFLAGS="%{optflags}" LDFLAGS="%{build_ldflags}" PREFIX=%{_prefix}

%install
%make_install PREFIX=%{_prefix} UDEVDIR=%{_udevrulesdir} MODLOADDIR=%{_modulesloaddir} SYSCONFDIR=%{_sysconfdir}
rm -rf %{buildroot}%{_datadir}/licenses/superdot

%post
modprobe uinput >/dev/null 2>&1 || :
udevadm control --reload-rules >/dev/null 2>&1 || :
udevadm trigger --action=change --sysname-match=uinput >/dev/null 2>&1 || :

%preun
# On removal (not upgrade): give logged-in users their desktop shortcuts back and stop SuperDot.
if [ "$1" -eq 0 ]; then
    for dir in /run/user/*; do
        uid="${dir##*/}"; bus="$dir/bus"
        [ -S "$bus" ] || continue
        user="$(id -nu "$uid" 2>/dev/null)" || continue
        runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
            python3 %{_prefix}/lib/superdot/superdot-setup --remove-hotkeys >/dev/null 2>&1 || :
        runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
            gdbus call --session --dest io.github.superdot.SuperDot --object-path /io/github/superdot/SuperDot \
            --method org.gtk.Actions.Activate quit "[]" "{}" >/dev/null 2>&1 || :
    done
fi

%files
%license LICENSE LICENSES/Unicode-3.0.txt
%doc README.md
%{_bindir}/superdot
%{_prefix}/lib/superdot/
%{_datadir}/applications/io.github.superdot.SuperDot.desktop
%{_datadir}/icons/hicolor/scalable/apps/io.github.superdot.SuperDot.svg
%{_metainfodir}/io.github.superdot.SuperDot.metainfo.xml
%config(noreplace) %{_sysconfdir}/xdg/autostart/superdot.desktop
%{_udevrulesdir}/70-superdot-uinput.rules
%{_modulesloaddir}/superdot-uinput.conf

%changelog
* Wed Nov 11 2026 SuperDot <saikatnjm@users.noreply.github.com> - 1.0.0-1
- First release: emoji, kaomoji and symbols with search, skin tones and recently used
