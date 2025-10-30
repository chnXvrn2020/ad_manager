# frozen_string_literal: true

require 'gtk3'

class ViewSearch < Gtk::Dialog

  attr_reader :keyword, :radio_active

  # 初期設定
  def initialize(parent, group_id)
    super(title: I18n.t('menu.search'), parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 200)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @group_id = group_id
    @radio_active = nil

    set_ui
    set_signal_connect

    show_all
  end

  private

  # UIの設定
  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box, padding: 10)

    @entry = Gtk::Entry.new
    @entry.set_size_request(550, 35)
    @entry.grab_focus
    h_box.pack_start(@entry, expand: true)

    radio_v_box = Gtk::Box.new(:vertical)
    h_box.pack_start(radio_v_box)

    @radio_btn = []
    radio_text = [I18n.t('view.group'), I18n.t('view.data')]

    radio_text.each_with_index do |text, index|
      @radio_btn[index] = if index.zero?
                            Gtk::RadioButton.new(label: text)
                          else
                            Gtk::RadioButton.new(label: text, member: @radio_btn[0])
                          end

      radio_v_box.pack_start(@radio_btn[index])
    end

    btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_box, padding: 30)

    @search_button = Gtk::Button.new(label: I18n.t('menu.search'))
    @search_button.set_size_request(270, 50)
    btn_box.pack_start(@search_button, expand: true)

    @close_button = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_button.set_size_request(270, 50)
    btn_box.pack_start(@close_button, expand: true)
  end

  # ウィゼットの設定
  def set_signal_connect
    # ラジオボタンのイベント
    @radio_btn.each do |radio|
      radio.signal_connect('toggled') do
        @radio_active = radio.label if radio.active?
      end
    end

    # 検索ボタンのクリックイベント
    @search_button.signal_connect('clicked') do
      @radio_active = I18n.t('view.group') if @radio_active.nil?

      @keyword = @entry.text.to_s.strip

      response(Gtk::ResponseType::OK)
      destroy
    end

    # リターンキーを押すときに、検索ボタンをクリックする
    signal_connect('key_press_event') do |widget, event|
      if event.keyval == Gdk::Keyval::KEY_Return ||
        event.keyval == Gdk::Keyval::KEY_KP_Enter

        @search_button.clicked

      end
      false
    end

    # 閉じるボタンのクリックイベント
    @close_button.signal_connect('clicked') do
      response(Gtk::ResponseType::CANCEL)
      destroy
    end
  end

end
