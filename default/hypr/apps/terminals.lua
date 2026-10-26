-- Define terminal tag so themes and bindings can single terminals out. Kestrel
-- launches TUIs and its own terminal windows under dedicated app-ids
-- (org.kestrel.btop, org.kestrel.terminal, TUI.float, ...), so match those too.
-- The class is matched in full, so foot's other app-id needs spelling out.
o.window(
  "(Alacritty|kitty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm|org\\.kestrel\\..*|TUI\\..*)",
  { tag = "+terminal" }
)
