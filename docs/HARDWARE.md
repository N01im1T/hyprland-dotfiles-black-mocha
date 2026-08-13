# Hardware adaptation

The installer detects graphics through PCI IDs, laptop status through battery and DMI data, touchpads through the input device inventory, and Bluetooth through sysfs. Detection is recorded in `hardware.toml` without usernames or fixed connector names.

Hyprland uses a fallback monitor rule with preferred mode, automatic placement and automatic DPI scale. This supports hotplug, 1080p, 1440p, 4K, ultrawide and mixed-output systems without assuming `HDMI-A-1`. Add explicit `hl.monitor()` calls only for stable, host-specific arrangements.

Laptop profiles add brightness and power-profile tooling. Battery widgets naturally disappear on desktop systems because Waybar has no battery device to render.
