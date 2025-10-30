# frozen_string_literal: true

require_relative '../views/home/home_index'
require_relative '../views/manage/manage_index'
require_relative '../views/manage/content/content_index'
require_relative '../views/content_view/view_index'
require_relative '../views/table/table_index'
require_relative '../views/statistics/statistics_index'

class LayoutChanger
  @@views = []

  def self.views
    @@views
  end

  # レイアウトの設定
  def set_layout(window)

    stack = Gtk::Stack.new
    stack.set_transition_type(:slide_left_right)
    window.add(stack)

    # 初期レイアウトの設定
    # 番号はレイアウトのidとなる
    @@views << HomeIndex.new(window, stack) # 0
    @@views << ManageIndex.new(window, stack) # 1
    @@views << ContentIndex.new(window, stack) # 2
    @@views << ViewIndex.new(window, stack) # 3
    @@views << TableIndex.new(window, stack) # 4
    @@views << StatisticsIndex.new(window, stack) # 5

    # 各レイアウトをstackに追加
    @@views.each_with_index do |view, index|
      stack.add_titled(view.frame, index.to_s, index.to_s)
    end

    # 初期レイアウトを表示
    stack
  end

  # レイアウトの切り替え
  def change_layout(stack, to_layout, id = nil)
    return if to_layout.nil?

    # stackを使ってレイアウトの切り替え
    stack.set_visible_child_name(to_layout.to_s)

    # 切り替え後のレイアウトの初期化
    @@views[to_layout].initialize_ui(id)

  end

  # ウィンドウが大きくなるのを防ぐコード
  def initialize_window
    @@views[2].initialize_window
    @@views[3].initialize_window
  end

end
