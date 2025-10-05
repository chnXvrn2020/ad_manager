# frozen_string_literal: true
require 'gtk3'
require 'i18n'

require 'ffi'
require 'fileutils'

module Win32
  extend FFI::Library
  ffi_lib 'user32'
  attach_function :MessageBeep, [:uint], :int
end

Dir.glob(File.join(__dir__, 'common/*.rb')).sort.each do |f|
  require_relative f
end

require_relative 'mapper/config/sqlite3'

Dir.glob(File.join(__dir__, 'models/*.rb')).sort.each do |f|
  require_relative f
end

Dir.glob(File.join(__dir__, 'mapper/sql/*.rb')).sort.each do |f|
  require_relative f
end

Dir.glob(File.join(__dir__, 'services/*.rb')).sort.each do |f|
  require_relative f
end

I18n.load_path += Dir[File.join('lib', 'ad_manager', 'apps', 'config', 'locales', '*.yml')]
I18n.available_locales = %i[en ja]
I18n.default_locale = :ja

Gtk::Settings.default.gtk_font_name = 'MEIRYO 14'

window = Gtk::Window.new(I18n.t('title.title'))
window.signal_connect('destroy') { Gtk.main_quit }
window.set_size_request(1200, 800)
window.resizable = false
window.set_position(:center_always)

layout_changer = LayoutChanger.new
stack = layout_changer.set_layout(window)

layout_changer.change_layout(stack, 0)

window.show_all
layout_changer.initialize_window

Gtk.main
