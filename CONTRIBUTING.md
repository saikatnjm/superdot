# Contributing to SuperDot

Thanks for helping! Bug reports, fixes, new kaomoji and symbols, and packaging help are all welcome.

## Reporting a bug

Open an [issue](https://github.com/saikatnjm/superdot/issues/new/choose) and include the output of:

```bash
superdot --doctor
```

plus your distro, desktop (GNOME, KDE, Cinnamon…), Wayland or X11, and the app you were typing into.
For more detail, run SuperDot in a terminal with logging on and repeat what went wrong:

```bash
superdot --quit; SUPERDOT_DEBUG=1 superdot --daemon
```

## Building

```bash
sudo apt install build-essential pkg-config libgtk-3-dev   # Fedora: gcc make gtk3-devel libX11-devel
make
./superdot --quit; ./superdot --daemon &   # run your build
./superdot                                 # open the panel
```

## Guidelines

- **Keep it light.** SuperDot is one small C program with GTK 3 and no runtime dependencies beyond it. Please don't add libraries, runtimes or network access.
- **Behave like Windows** unless there is a good Linux reason not to.
- Keep the code style of the file you're editing (4-space indent, C11 + GNU extensions, GLib types).
- Build with no warnings: `make CFLAGS="-Os -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Werror"`.
- Test on Wayland and on X11 if you change anything about pasting or the clipboard.
- One topic per pull request, with a short description of what changed and how you tested it.

## Adding kaomoji or symbols

Edit [`data/kaomoji.txt`](data/kaomoji.txt) or [`data/symbols.txt`](data/symbols.txt) (the format is described at the top of each file), then regenerate the built-in data:

```bash
make data    # downloads the latest Unicode emoji list + CLDR keywords, rebuilds emoji-data.h
make
```

## License

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
