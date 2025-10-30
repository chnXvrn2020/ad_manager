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

# ファイルの読み込み
dir = %w[common models mapper/sql services]

dir.each do |d|
  Dir.glob(File.join(__dir__, d, '*.rb')).sort.each do |f|
    require_relative f
  end
end

require_relative 'mapper/config/sqlite3'

# 言語の設定
I18n.load_path += Dir[File.join('lib', 'ad_manager', 'apps', 'config', 'locales', '*.yml')]
I18n.available_locales = %i[en ja]
I18n.default_locale = :ja

# フォントの設定
Gtk::Settings.default.gtk_font_name = 'MEIRYO 14'

# ウィンドウ作成
window = Gtk::Window.new(I18n.t('title.title'))
window.signal_connect('destroy') { Gtk.main_quit }
window.set_size_request(1200, 800)
window.resizable = false
window.set_position(:center_always)

# レイアウトの切り替えの設定
layout_changer = LayoutChanger.new
stack = layout_changer.set_layout(window)

# 初期画面の設定
layout_changer.change_layout(stack, 0)

# 画面の表示
window.show_all
layout_changer.initialize_window

Gtk.main
