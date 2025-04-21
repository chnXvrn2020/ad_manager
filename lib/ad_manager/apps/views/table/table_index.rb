# frozen_string_literal: true

require_relative 'table_search'

class TableIndex
  attr_reader :frame

  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new

    set_ui
    set_signal_connect

  end

  def initialize_ui(id)

  end

  private

  def set_ui
    @main_v_box = Gtk::Box.new(:vertical)
    @main_v_box.set_margin_start(30)
    @main_v_box.set_margin_end(30)
    @main_v_box.set_margin_top(20)
    @main_v_box.set_margin_bottom(20)

    @frame.add(@main_v_box)

    tree_v_box = Gtk::Box.new(:vertical)
    @main_v_box.pack_start(tree_v_box, expand: true)

    @tree_view_scroll = Gtk::ScrolledWindow.new
    @tree_view_scroll.set_size_request(400,600)
    tree_v_box.pack_start(@tree_view_scroll, expand: true)

    @tree_view = Gtk::TreeView.new
    @tree_view_scroll.add(@tree_view)

    btn_h_box = Gtk::Box.new(:horizontal)
    @main_v_box.pack_start(btn_h_box, expand: true)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(550, 50)
    btn_h_box.pack_start(@search_btn, expand: true)

    @back_btn = Gtk::Button.new(label: I18n.t('menu.back'))
    @back_btn.set_size_request(550, 50)
    btn_h_box.pack_start(@back_btn, expand: true)
  end

  def set_signal_connect
    @search_btn.signal_connect('clicked') do
      table_search = TableSearch.new(@window, I18n.t('menu.search'))

      table_search.signal_connect('response') do |widget, response|

      end
    end

    @back_btn.signal_connect('clicked') do
      layout_changer = LayoutChanger.new

      layout_changer.change_layout(@stack, 0)
    end
  end

end
