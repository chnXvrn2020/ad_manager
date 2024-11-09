# frozen_string_literal: true

require 'gtk3'

class HomeSearch < Gtk::Dialog

  attr_reader :keyword

  def initialize(parent, menu)
    super(title: menu, parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 200)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @menu = menu

    set_ui
    set_signal_connect

    show_all
  end

  private

  def set_ui

    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(650, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_box, padding: 30)

    @search_button = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_button.set_size_request(270, 50)
    btn_box.pack_start(@search_button, expand: true)

    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(270, 50)
    btn_box.pack_start(@close_button, expand: true)

  end

  def set_signal_connect

    @search_button.signal_connect('clicked') do
      if @entry.text.to_s.strip.empty?
        dialog_message(self, :warning, :empty_entry)
        @entry.grab_focus

        next
      end

      @keyword = @entry.text.to_s.strip

      response(Gtk::ResponseType::OK)
      destroy
    end

    signal_connect('key_press_event') do |widget, event|
      if event.keyval == Gdk::Keyval::KEY_Return ||
        event.keyval == Gdk::Keyval::KEY_KP_Enter
        @search_button.clicked
      end
      false
    end

    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::CANCEL)
      destroy
    end

  end

end
