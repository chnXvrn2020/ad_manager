# frozen_string_literal: true

require_relative '../../controllers/common_controller'

require 'gtk3'

class TableSearch < Gtk::Dialog

  attr_reader :keyword

  def initialize(parent, menu)
    super(title: menu, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(1000, 700)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @menu = menu
    @common_controller = CommonController.new

    set_ui
    set_signal_connect

    show_all
  end

  private

  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(800, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    @original_combo = Gtk::ComboBoxText.new
    @original_combo.set_size_request(150, 35)
    h_box.pack_start(@original_combo)

    set_combo_box
    # no_original
    anime_original
    book_original

    bottom_h_box = Gtk::Box.new(:horizontal)
    child.pack_start(bottom_h_box, padding: 10)

    @search_btn = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_btn.set_size_request(400, 50)
    bottom_h_box.pack_start(@search_btn, expand: true)

    @close_btn = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_btn.set_size_request(400, 50)
    bottom_h_box.pack_start(@close_btn, expand: true)
  end

  def set_signal_connect
    @original_combo.signal_connect('changed') do |widget|
      if widget.active == 0

      else

      end
    end

    @search_btn.signal_connect('clicked') do

    end

    @close_btn.signal_connect('clicked') do
      response(Gtk::ResponseType::CANCEL)
      destroy
    end
  end

  def set_combo_box
    text_renderer = Gtk::CellRendererText.new
    combo_model = Gtk::ListStore.new(String, Integer)

    original = begin
                 @common_controller.get_type_menu('original')
               rescue StandardError => e
                 dialog_message(@window, :error, :db_error, e.message)
                 return
               end

    primary = combo_model.append
    primary[0] = I18n.t('menu.original')
    primary[1] = 0

    original.each do |item|
      iter = combo_model.append
      iter[0] = item.name
      iter[1] = item.id
    end

    @original_combo.clear
    @original_combo.model = combo_model
    @original_combo.pack_start(text_renderer, true)
    @original_combo.set_attributes(text_renderer, text: 0)
    @original_combo.active = 0
  end

  def no_original
    @no_original_main_box = Gtk::Box.new(:vertical)
    child.pack_start(@no_original_main_box, expand: true)

    @no_original_label = Gtk::Label.new(I18n.t('table_search.no_original'))
    @no_original_main_box.pack_start(@no_original_label)
  end

  def anime_original
    @anime_original_main_box = Gtk::Box.new(:vertical)
    child.pack_start(@anime_original_main_box, expand: true)

    first_h_box = Gtk::Box.new(:horizontal)
    @anime_original_main_box.pack_start(first_h_box)

    @storage_combo = Gtk::ComboBoxText.new
    @storage_combo.set_size_request(150, 35)
    first_h_box.pack_start(@storage_combo, padding: 25)
  end

  def book_original
    @book_original_main_box = Gtk::Box.new(:vertical)
    child.pack_start(@book_original_main_box, expand: true)
  end
end
