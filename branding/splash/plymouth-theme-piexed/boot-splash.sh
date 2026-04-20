#!/bin/bash
# Piẻxed OS Professional Boot Animation Script
# Creates Dell/macOS style boot screen

set -e

THEME_DIR="/usr/share/plymouth/themes/piexed"
LOGO_PATH="$THEME_DIR/logo.png"

echo "=== Piẻxed OS Boot Splash Configuration ==="

# Create theme directory
sudo mkdir -p "$THEME_DIR"

# Copy logo
if [ -f "logo-white-black.png" ]; then
    sudo cp logo-white-black.png "$LOGO_PATH"
    echo "Logo installed"
fi

# Create professional plymouth theme config
sudo tee "$THEME_DIR/plymouthd" > /dev/null << 'EOF'
[Plymouth Theme]
Name=Piexed OS
Description=Professional boot theme
ModuleName=two-step
EOF

# Two-step animation configuration
sudo tee "$THEME_DIR/two-step.script" > /dev/null << 'EOF'
# Piẻxed OS - Professional Boot Animation
# Dell/macOS inspired loading screen

# Colors
bg_color = "0.102, 0.102, 0.180";  # #1A1A2E
fg_color = "1.0, 1.0, 1.0";        # White
accent_color = "0.902, 0.224, 0.275"; # #E63946

Window.SetBackgroundTopColor (bg_color);
Window.SetBackgroundBottomColor (bg_color);

# Logo image
logo = Image ("logo.png");
logo_width = logo.GetWidth ();
logo_height = logo.GetHeight ();

# Scale logo to fit
if (logo_width > 256) {
    ratio = 256.0 / logo_width;
    logo_width = logo_width * ratio;
    logo_height = logo_height * ratio;
}

# Center positions
logo_x = (Window.GetMaxWidth () - logo_width) / 2;
logo_y = Window.GetMaxHeight () / 3;

# Progress bar
progress_box_width = 300;
progress_box_height = 4;
progress_box_x = (Window.GetMaxWidth () - progress_box_width) / 2;
progress_box_y = Window.GetMaxHeight () * 0.7;

# Progress box (background)
progress_outline = Rectangle ();
progress_outline.SetX (progress_box_x);
progress_outline.SetY (progress_box_y);
progress_outline.SetWidth (progress_box_width);
progress_outline.SetHeight (progress_box_height);
progress_outline.SetColor ("0.2, 0.2, 0.3");

# Progress fill
progress_fill = Rectangle ();
progress_fill.SetX (progress_box_x);
progress_fill.SetY (progress_box_y);
progress_fill.SetWidth (0);
progress_fill.SetHeight (progress_box_height);
progress_fill.SetColor (accent_color);

# Title
title = Text();
title.SetFontName ("Ubuntu");
title.SetFontSize (28);
title.SetTextColor (fg_color);
title.SetText ("Piẻxed OS");
title_width = title.GetWidth ();
title.SetPosition (Window.GetMaxWidth()/2 - title_width/2, logo_y + logo_height + 40);

# Subtitle (version)
subtitle = Text();
subtitle.SetFontName ("Ubuntu");
subtitle.SetFontSize (14);
subtitle.SetTextColor ("0.6, 0.6, 0.6");
subtitle.SetText ("Professional Edition");
subtitle_width = subtitle.GetWidth ();
subtitle.SetPosition (Window.GetMaxWidth()/2 - subtitle_width/2, logo_y + logo_height + 70);

# Message
message = Text();
message.SetFontName ("Ubuntu");
message.SetFontSize (14);
message.SetTextColor (fg_color);
message.SetText ("Starting...");
message_width = message.GetWidth ();
message.SetPosition (Window.GetMaxWidth()/2 - message_width/2, progress_box_y + 30);

# Progress percentage
percent = Text();
percent.SetFontName ("Ubuntu");
percent.SetFontSize (14);
percent.SetTextColor ("0.6, 0.6, 0.6");
percent.SetText ("");
percent.SetPosition (progress_box_x + progress_box_width + 20, progress_box_y - 6);

# Animation callback
fun animate_callback () {
    if (boot_progress_eof) {
        # Boot complete
    } else {
        progress_fill.SetWidth (progress_box_width * progress);
    }
}

Plymouth.SetBootProgressFunction (animate_callback);

# Message callback
fun message_callback (text) {
    message.SetText (text);
}

Plymouth.SetMessageFunction (message_callback);

# Display callback (initial render)
fun display_callback () {
    # Logo would be drawn here if using image
}

Plymouth.SetDisplayFunction (display_callback);
EOF

echo "Boot splash configured successfully!"
echo ""
echo "To apply changes, run:"
echo "  sudo plymouth-set-default-theme piexed"
echo "  sudo update-initramfs -u"
echo "  sudo reboot"