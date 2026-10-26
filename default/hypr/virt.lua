local paths = require("default.hypr.paths")

-- The virtual GPUs QEMU/UTM expose (virtio-gpu, VMware SVGA, ...) do not light
-- up Hyprland's DRM hardware-cursor plane, so the pointer is invisible on the
-- physical display. Render it in software on virtual machines.
local hw_vm = paths.kestrel_path .. "/bin/kestrel-hw-vm"

if o.shell_succeeds(o.shell_quote(hw_vm)) then
  hl.config({
    cursor = {
      no_hardware_cursors = true,
    },
  })
end
