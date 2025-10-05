# frozen_string_literal: true

require_relative '../../../controllers/anime_controller'
require_relative '../../../controllers/book_controller'
require_relative '../../../controllers/common_controller'
require_relative 'data_search'

require 'gtk3'

class DataSelector < Gtk::Dialog

  def initialize(parent, content_type, original, id)
    super(title: '', parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(1000, 500)
    set_position(Gtk::WindowPosition::CENTER)

    @parent = parent
    @content_type = content_type
    @original = original
    @id = id
    @anime_controller = AnimeController.new
    @book_controller = BookController.new
    @common_controller = CommonController.new
    @keyword = nil
    @common = load_common_data

    self.title = "#{@common.name}#{I18n.t('data.load')}"

    set_ui
    load_data
    load_selected_data
    set_signal_connect

    show_all
  end

  def load_common_data
    @common_controller.get_one_common(@original)
  end

  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    label = Gtk::Label.new
    label.set_markup("<span font='25'>#{@common.name}#{I18n.t('data.load')}</span>")
    h_box.pack_start(label, expand: true)

    list_h_box = Gtk::Box.new(:horizontal)
    child.pack_start(list_h_box, padding: 20)

    selected_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(selected_list_v_box, expand: true)

    selected_label = Gtk::Label.new
    selected_label.text = I18n.t('data.selected')
    selected_list_v_box.pack_start(selected_label)

    @selected_list_scroll = Gtk::ScrolledWindow.new
    @selected_list_scroll.set_size_request(400, 300)
    selected_list_v_box.pack_start(@selected_list_scroll, expand: true)

    @selected_list = Gtk::ListBox.new
    @selected_list_scroll.add(@selected_list)

    data_list_v_box = Gtk::Box.new(:vertical)
    list_h_box.pack_start(data_list_v_box, expand: true)

    data_label = Gtk::Label.new
    data_label.text = I18n.t('data.not_selected')
    data_list_v_box.pack_start(data_label)

    @data_list_scroll = Gtk::ScrolledWindow.new
    @data_list_scroll.set_size_request(400, 300)
    data_list_v_box.pack_start(@data_list_scroll, expand: true)

    @data_list = Gtk::ListBox.new
    @data_list_scroll.add(@data_list)

    btn_h_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_h_box, padding: 20)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(330, 50)
    btn_h_box.pack_start(@search_btn, expand: true)

    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(330, 50)
    btn_h_box.pack_start(@close_button, expand: true)
  end

  def set_signal_connect
    @data_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i
          add_data(widget, item, selected_row)
        end
      end
    end

    @selected_list.signal_connect('button_press_event') do |widget, event|
      if event.type == Gdk::EventType::BUTTON2_PRESS
        selected_row = widget.selected_row

        if selected_row
          item = selected_row.name.to_i
          remove_selected_data(widget, item, selected_row)
        end
      end
    end

    @search_btn.signal_connect('clicked') do
      data_search = DataSearch.new(self, @search_btn.label)

      data_search.signal_connect('response') do |widget, response|
        if response == Gtk::ResponseType::OK
          @keyword = data_search.keyword

          load_data
        end
      end
    end

    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def load_data
    clear_list_box(@data_list)

    data = if @common.name == I18n.t('original.anime')
             @anime_controller.get_unselected_anime_list(@id, @keyword)
           else
             @book_controller.get_unselected_book_list(@original, @id, @keyword)
           end

    if data.is_a?(String)
      dialog_message(self, :error, :db_error, data)
      return
    end

    data.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @data_list.add(row)
    end

    @data_list_scroll.vadjustment.value = 0.0
    @data_list.show_all
  end

  def load_selected_data
    clear_list_box(@selected_list)

    data = if @common.name == I18n.t('original.anime')
             @anime_controller.get_anime_list(@id)
           else
             @book_controller.get_book_list(@original, @id)
           end

    if data.is_a?(String)
      dialog_message(self, :error, :db_error, data)
      return
    end

    data.each do |item|
      row = Gtk::ListBoxRow.new
      row.add(Gtk::Label.new(item.name))
      row.name = item.id.to_s
      row.halign = Gtk::Align::START

      @selected_list.add(row)
    end

    @selected_list_scroll.vadjustment.value = 0.0
    @selected_list.show_all
  end

  def add_data(widget, item, selected_row)
    result = if @common.name == I18n.t('original.anime')
               @anime_controller.set_mapping_anime(@id, item)
             else
               @book_controller.set_mapping_book(@id, item)
             end

    if result.is_a?(String)
      dialog_message(self, :error, :db_error, result)
      return
    end

    row = Gtk::ListBoxRow.new
    row.add(Gtk::Label.new(selected_row.child.text))
    row.name = item.to_s
    row.halign = Gtk::Align::START

    @selected_list.add(row)
    @selected_list.show_all

    widget.remove(selected_row)
  end

  def remove_selected_data(widget, item, selected_row)
    result = if @common.name == I18n.t('original.anime')
               @anime_controller.remove_mapping_anime(@id, item)
             else
               @book_controller.remove_mapping_book(@id, item)
             end

    if result.is_a?(String)
      dialog_message(self, :error, :db_error, result)
      return
    end

    row = Gtk::ListBoxRow.new
    row.add(Gtk::Label.new(selected_row.child.text))
    row.name = item.to_s
    row.halign = Gtk::Align::START

    @data_list.add(row)

    @data_list.set_sort_func do |row1, row2|
      row1.child.text <=> row2.child.text
    end

    @data_list.show_all

    widget.remove(selected_row)
  end
end
