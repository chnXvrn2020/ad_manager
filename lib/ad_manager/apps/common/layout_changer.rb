# frozen_string_literal: true

require_relative '../views/home/home_index'
require_relative '../views/manage/manage_index'
require_relative '../views/manage/content/content_index'
require_relative '../views/content_view/view_index'
require_relative '../views/table/table_index'

class LayoutChanger
  @@views = []

  def self.views
    @@views
  end

  def set_layout(window)

    stack = Gtk::Stack.new
    stack.set_transition_type(:slide_left_right)
    window.add(stack)

    @@views << HomeIndex.new(window, stack) # 0
    @@views << ManageIndex.new(window, stack) # 1
    @@views << ContentIndex.new(window, stack) # 2
    @@views << ViewIndex.new(window, stack) # 3
    @@views << TableIndex.new(window, stack) # 4

    @@views.each_with_index do |view, index|
      stack.add_titled(view.frame, index.to_s, index.to_s)
    end

    stack
  end

  def change_layout(stack, to_layout, id = nil)
    stack.set_visible_child_name(to_layout.to_s)

    @@views[to_layout].initialize_ui(id)

  end

  def initialize_window
    @@views[2].initialize_window
    @@views[3].initialize_window
  end

end
