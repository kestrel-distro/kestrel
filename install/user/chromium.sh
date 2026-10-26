# Chromium ships in the base packages, so it never goes through
# kestrel-install-browser. Without this, the bundled extensions load but have no
# native messaging host to talk to.
