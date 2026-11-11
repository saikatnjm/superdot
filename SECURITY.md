# Security Policy

## Supported versions

Only the latest release gets security fixes.

## Reporting a vulnerability

Please **don't open a public issue**. Report it privately through GitHub's
[private vulnerability reporting](https://github.com/saikatnjm/superdot/security/advisories/new).
You'll get a reply within a week, and a fix is released as soon as possible.

## What SuperDot can access

So you can judge the impact of a bug:

- **Typing for you:** to type into Wayland apps SuperDot creates a virtual keyboard through `/dev/uinput`. The installer adds a udev rule (`70-superdot-uinput.rules`) that gives the *logged-in* user access to `/dev/uinput`. Any program running as that user can then also create virtual input devices. Remove the rule (or install with `--no-sudo`) if you don't want that; SuperDot then only copies.
- **Clipboard:** while you pick an emoji, SuperDot keeps a copy of your clipboard in memory (never on disk) so it can put it back. It is dropped once you copy something else.
- **Files:** settings in `~/.config/superdot/config.ini` and recently used emoji in `~/.local/share/superdot/recent.txt`, both readable only by you.
- **Network:** none. SuperDot never connects to the internet.
