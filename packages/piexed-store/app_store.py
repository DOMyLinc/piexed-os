#!/usr/bin/env python3
"""
Piexed OS App Store
A simple, beautiful application store for installing software
"""

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gio', '2.0')

from gi.repository import Gtk, Gdk, Gio, Pango, GLib
import subprocess
import threading
import os

# App Store Configuration
APP_STORE_VERSION = "1.0.0"

# Categories
CATEGORIES = [
    {"id": "all", "name": "All Applications", "icon": "applications-all"},
    {"id": "featured", "name": "Featured", "icon": "starred"},
    {"id": "productivity", "name": "Productivity", "icon": "applications-office"},
    {"id": "development", "name": "Development", "icon": "applications-development"},
    {"id": "games", "name": "Games", "icon": "applications-games"},
    {"id": "multimedia", "name": "Multimedia", "icon": "applications-multimedia"},
    {"id": "graphics", "name": "Graphics", "icon": "applications-graphics"},
    {"id": "network", "name": "Network", "icon": "applications-internet"},
    {"id": "system", "name": "System Tools", "icon": "applications-system"}
]

# Sample App Database
APPS = [
    {"id": "firefox", "name": "Firefox", "summary": "Fast, private web browser", "category": "network", "pkgname": "firefox", "icon": "firefox", "rating": 4.5, "is_featured": True, "is_installed": False},
    {"id": "libreoffice", "name": "LibreOffice", "summary": "Complete office suite", "category": "productivity", "pkgname": "libreoffice", "icon": "libreoffice", "rating": 4.3, "is_featured": True, "is_installed": False},
    {"id": "vlc", "name": "VLC", "summary": "Play all your videos", "category": "multimedia", "pkgname": "vlc", "icon": "vlc", "rating": 4.7, "is_featured": True, "is_installed": False},
    {"id": "gimp", "name": "GIMP", "summary": "Image editor", "category": "graphics", "pkgname": "gimp", "icon": "gimp", "rating": 4.4, "is_featured": True, "is_installed": False},
    {"id": "code", "name": "VS Code", "summary": "Code editor", "category": "development", "pkgname": "code", "icon": "code", "rating": 4.8, "is_featured": True, "is_installed": False},
    {"id": "steam", "name": "Steam", "summary": "Gaming platform", "category": "games", "pkgname": "steam", "icon": "steam", "rating": 4.5, "is_featured": True, "is_installed": False},
    {"id": "blender", "name": "Blender", "summary": "3D creation suite", "category": "graphics", "pkgname": "blender", "icon": "blender", "rating": 4.6, "is_featured": True, "is_installed": False},
    {"id": "thunderbird", "name": "Thunderbird", "summary": "Email client", "category": "productivity", "pkgname": "thunderbird", "icon": "thunderbird", "rating": 4.2, "is_featured": False, "is_installed": False},
    {"id": "inkscape", "name": "Inkscape", "summary": "Vector graphics editor", "category": "graphics", "pkgname": "inkscape", "icon": "inkscape", "rating": 4.3, "is_featured": False, "is_installed": False},
    {"id": "obs", "name": "OBS Studio", "summary": "Video recording", "category": "multimedia", "pkgname": "obs-studio", "icon": "obs", "rating": 4.7, "is_featured": True, "is_installed": False},
    {"id": "transmission", "name": "Transmission", "summary": "BitTorrent client", "category": "network", "pkgname": "transmission-gtk", "icon": "transmission", "rating": 4.5, "is_featured": False, "is_installed": False},
    {"id": "filezilla", "name": "FileZilla", "summary": "FTP client", "category": "network", "pkgname": "filezilla", "icon": "filezilla", "rating": 4.3, "is_featured": False, "is_installed": False},
    {"id": "audacity", "name": "Audacity", "summary": "Audio editor", "category": "multimedia", "pkgname": "audacity", "icon": "audacity", "rating": 4.4, "is_featured": False, "is_installed": False},
    {"id": "shotwell", "name": "Shotwell", "summary": "Photo organizer", "category": "graphics", "pkgname": "shotwell", "icon": "shotwell", "rating": 4.1, "is_featured": False, "is_installed": True},
]


class AppStoreWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Piexed Store")
        self.set_default_size(1000, 700)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.modify_bg(Gtk.StateType.NORMAL, Gdk.color_parse("#FAFAFA"))

        self.current_category = "all"
        self.search_query = ""

        self.setup_ui()

    def setup_ui(self):
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        self.add(main_box)

        # Sidebar
        sidebar = self.create_sidebar()
        main_box.pack_start(sidebar, False, False, 0)

        # Content
        content = self.create_content()
        main_box.pack_start(content, True, True, 0)

    def create_sidebar(self):
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        sidebar.set_size_request(220, -1)
        sidebar.modify_bg(Gtk.StateType.NORMAL, Gdk.color_parse("#1A1A2E"))

        # Logo
        logo_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        logo_box.set_margin_top(20)
        logo_box.set_margin_start(15)
        logo_box.set_margin_end(15)
        logo_box.set_margin_bottom(20)

        logo_icon = Gtk.Image()
        logo_icon.set_from_icon_name("strawberry", Gtk.IconSize.DIALOG)

        logo_label = Gtk.Label()
        logo_label.set_markup("<span font='18' color='white'><b>Piexed</b></span>")
        logo_label.set_xalign(0)

        logo_box.pack_start(logo_icon, False, False, 0)
        logo_box.pack_start(logo_label, True, True, 0)
        sidebar.pack_start(logo_box, False, False, 0)

        # Categories
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        categories_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        categories_box.set_margin_top(10)
        categories_box.set_margin_start(10)
        categories_box.set_margin_end(10)

        for cat in CATEGORIES:
            btn = Gtk.Button()
            btn.set_size_request(-1, 42)
            btn.set_relief(Gtk.ReliefStyle.NONE)
            btn.connect("clicked", self.on_category_clicked, cat["id"])

            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            btn.add(box)

            icon = Gtk.Image()
            icon.set_from_icon_name(cat["icon"], Gtk.IconSize.MENU)
            icon.modify_fg(Gtk.StateType.NORMAL, Gdk.color_parse("#FFFFFF"))

            label = Gtk.Label(cat["name"])
            label.set_xalign(0)
            label.modify_fg(Gtk.StateType.NORMAL, Gdk.color_parse("#FFFFFF"))
            label.modify_font(Pango.FontDescription.from_string("Ubuntu 11"))

            box.pack_start(icon, False, False, 0)
            box.pack_start(label, True, True, 0)
            categories_box.pack_start(btn, False, False, 0)

        scrolled.add(categories_box)
        sidebar.pack_start(scrolled, True, True, 0)

        # Update button
        update_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        update_box.set_margin(15)

        update_btn = Gtk.Button(label="Check for Updates")
        update_btn.set_size_request(-1, 40)
        update_btn.connect("clicked", self.on_update_clicked)
        update_box.pack_start(update_btn, False, False, 0)

        version_label = Gtk.Label()
        version_label.set_markup(f"<span font='9' color='#666666'>v{APP_STORE_VERSION}</span>")
        version_label.set_xalign(0.5)
        update_box.pack_start(version_label, False, False, 0)

        sidebar.pack_start(update_box, False, False, 0)

        return sidebar

    def create_content(self):
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        header.set_margin_top(15)
        header.set_margin_start(20)
        header.set_margin_end(20)
        header.set_margin_bottom(15)

        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        title = Gtk.Label()
        title.set_markup("<span font='20' font_weight='bold' color='#333333'>App Store</span>")

        search_entry = Gtk.SearchEntry()
        search_entry.set_placeholder_text("Search applications...")
        search_entry.set_size_request(280, -1)
        search_entry.connect("search-changed", self.on_search_changed)

        top_row.pack_start(title, False, False, 0)
        top_row.pack_end(search_entry, False, False, 0)

        header.pack_start(top_row, False, False, 0)

        self.category_title = Gtk.Label()
        self.category_title.set_markup("<span font='13' color='#666666'>All Applications</span>")
        self.category_title.set_xalign(0)
        header.pack_start(self.category_title, False, False, 0)

        content.pack_start(header, False, False, 0)

        # Apps grid
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.NONE)

        self.apps_grid = self.create_apps_grid()
        scrolled.add(self.apps_grid)

        content.pack_start(scrolled, True, True, 0)

        return content

    def create_apps_grid(self):
        grid = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        grid.set_margin(20)

        row = None
        col_count = 0

        for app in self.get_filtered_apps():
            if col_count == 0:
                row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
                grid.pack_start(row, False, False, 0)

            card = self.create_app_card(app)
            row.pack_start(card, True, True, 0)
            col_count += 1

            if col_count == 3:
                col_count = 0

        if col_count > 0:
            while col_count < 3:
                spacer = Gtk.Box()
                spacer.set_size_request(240, 220)
                row.pack_start(spacer, True, True, 0)
                col_count += 1

        return grid

    def create_app_card(self, app):
        card = Gtk.Frame()
        card.set_size_request(240, 220)
        card.set_shadow_type(Gtk.ShadowType.IN)
        card.modify_bg(Gtk.StateType.NORMAL, Gdk.color_parse("#FFFFFF"))

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(12)
        box.set_margin_bottom(12)
        box.set_margin_start(12)
        box.set_margin_end(12)

        # Icon and info
        info = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        icon = Gtk.Image()
        icon.set_from_icon_name(app["icon"], Gtk.IconSize.DND)
        icon.set_size_request(56, 56)

        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        name = Gtk.Label()
        name.set_markup(f"<span font='13' font_weight='bold' color='#333333'>{app['name']}</span>")
        name.set_xalign(0)

        rating = Gtk.Label()
        rating.set_markup(f"<span font='10' color='#FFB800'>★ {app['rating']}</span>")
        rating.set_xalign(0)

        info_box.pack_start(name, False, False, 0)
        info_box.pack_start(rating, False, False, 0)

        info.pack_start(icon, False, False, 0)
        info.pack_start(info_box, True, True, 0)

        box.pack_start(info, False, False, 0)

        # Description
        desc = Gtk.Label()
        desc.set_text(app["summary"])
        desc.set_line_wrap(True)
        desc.set_max_width_chars(35)
        desc.set_alignment(0, 0.5)
        desc.modify_fg(Gtk.StateType.NORMAL, Gdk.color_parse("#666666"))
        desc.modify_font(Pango.FontDescription.from_string("Ubuntu 10"))

        box.pack_start(desc, False, False, 0)

        # Button
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)

        if app["is_installed"]:
            btn = Gtk.Button(label="Open")
            btn.set_size_request(80, 32)
            btn.modify_bg(Gtk.StateType.NORMAL, Gdk.color_parse("#2A9D8F"))
            btn.modify_fg(Gtk.StateType.NORMAL, Gdk.color_parse("#FFFFFF"))
        else:
            btn = Gtk.Button(label="Install")
            btn.set_size_request(80, 32)
            btn.modify_bg(Gtk.StateType.NORMAL, Gdk.color_parse("#E63946"))
            btn.modify_fg(Gtk.StateType.NORMAL, Gdk.color_parse("#FFFFFF"))
            btn.connect("clicked", self.on_install_clicked, app)

        btn_box.pack_end(btn, False, False, 0)
        box.pack_start(btn_box, False, False, 0)

        card.add(box)

        return card

    def get_filtered_apps(self):
        filtered = []
        for app in APPS:
            if self.current_category != "all" and self.current_category != "featured":
                if app["category"] != self.current_category:
                    continue
            elif self.current_category == "featured":
                if not app["is_featured"]:
                    continue

            if self.search_query:
                query = self.search_query.lower()
                if query not in app["name"].lower() and query not in app["summary"].lower():
                    continue

            filtered.append(app)
        return filtered

    def on_category_clicked(self, widget, category_id):
        self.current_category = category_id
        for cat in CATEGORIES:
            if cat["id"] == category_id:
                self.category_title.set_markup(f"<span font='13' color='#666666'>{cat['name']}</span>")
                break
        self.refresh_grid()

    def on_search_changed(self, widget):
        self.search_query = widget.get_text()
        self.refresh_grid()

    def refresh_grid(self):
        parent = self.apps_grid.get_parent()
        if parent:
            parent.remove(self.apps_grid)
            scrolled = Gtk.ScrolledWindow()
            scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
            self.apps_grid = self.create_apps_grid()
            scrolled.add(self.apps_grid)
            parent.pack_start(scrolled, True, True, 0)
            parent.show_all()

    def on_install_clicked(self, widget, app):
        dialog = Gtk.MessageDialog(self, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, f"Installing {app['name']}...")
        dialog.run()
        dialog.destroy()

        def install_thread():
            try:
                result = subprocess.run(["pkexec", "apt-get", "install", "-y", app["pkgname"]], capture_output=True, text=True)
                GLib.idle_add(lambda: self.on_install_complete(app, result.returncode == 0))
            except Exception as e:
                GLib.idle_add(lambda: self.on_install_failed(app, str(e)))

        threading.Thread(target=install_thread).start()

    def on_install_complete(self, app, success):
        if success:
            app["is_installed"] = True
            self.refresh_grid()
            dialog = Gtk.MessageDialog(self, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, f"{app['name']} installed!")
            dialog.run()
            dialog.destroy()
        else:
            self.on_install_failed(app, "Installation failed")

    def on_install_failed(self, app, error):
        dialog = Gtk.MessageDialog(self, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, f"Failed: {error}")
        dialog.run()
        dialog.destroy()

    def on_update_clicked(self, widget):
        dialog = Gtk.MessageDialog(self, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "Checking for updates...")
        dialog.run()
        dialog.destroy()

        def update_thread():
            try:
                subprocess.run(["pkexec", "apt-get", "update"], capture_output=True)
                GLib.idle_add(lambda: self.on_update_complete(True))
            except:
                GLib.idle_add(lambda: self.on_update_complete(False))

        threading.Thread(target=update_thread).start()

    def on_update_complete(self, success):
        dialog = Gtk.MessageDialog(self, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "All packages are up to date!" if success else "Update failed")
        dialog.run()
        dialog.destroy()


def main():
    app = AppStoreWindow()
    app.connect("destroy", Gtk.main_quit)
    app.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
