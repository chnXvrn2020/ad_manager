# frozen_string_literal: true

# ファイルパスの取得
def img_path
  './files/akiba_images/'
end

def no_image_path
  './assets/images/no_image_tate.jpg'
end

# 現在時刻の取得
def current_datetime
  Time.now.strftime('%Y-%m-%d %H:%M:%S')
end

# 現在日付の取得
def current_date
  Time.now.strftime('%Y-%m-%d')
end

# ファイル名の為の日付の取得
def file_datetime
  Time.now.strftime('%Y%m%d%H%M%S')
end

# テキストのオーバーフロア処理
def truncate_string(string, type)
  uni_byte = 4

  # 画面ごとに長さを変える
  max_length = case type
               when 'manage'
                 uni_byte * 20
               else
                 uni_byte * 12
               end

  current_length = 0
  result = String.new

  # 文字列をchar単位で処理して、長さを調整する
  string.each_char do |char|
    char_length = char.bytesize == 1 ? 2 : 4

    if current_length + char_length > max_length
      result << "..."
      break
    end

    result << char
    current_length += char_length
  end

  result

end

# ラジオボタンの値を返す
def radio_to_type(text)
  case text
  when I18n.t('radio_menu.content')
    'content'
  when I18n.t('radio_menu.studio')
    'studio'
  when I18n.t('radio_menu.publisher')
    'publisher'
  when I18n.t('radio_menu.storage')
    'storage'
  when I18n.t('radio_menu.rip')
    'rip'
  when I18n.t('radio_menu.media')
    'media'
  when I18n.t('radio_menu.ratio')
    'ratio'
  when I18n.t('radio_menu.original')
    'original'
  end
end

# リストボックスの内容をクリアする
def clear_list_box(list_box)
  list_box.children.each { |row| list_box.remove(row) }
end

# メッセージを表示する
def dialog_message(parent, dialog_type, type, error = nil, custom = nil)

  # 状態ごとに分岐する
  dialog_title = case dialog_type
                 when :error
                   message = error_dialog(type, error)
                   I18n.t('error.error_title')
                 when :warning
                   message = warning_dialog(type)
                   I18n.t('warning.warning_title')
                 when :custom
                   message = custom['message']
                   dialog_type = :info
                   custom['title']
                 else
                   message = alert_dialog(type)
                   I18n.t('alert.alert_title')
                 end

  dialog = Gtk::MessageDialog.new(parent: parent, flags: :destroy_with_parent, type: dialog_type,
                                  buttons_type: :ok, message: message)
  dialog.set_title(dialog_title)

  # 確認ボタン
  dialog.action_area.children.each do |button|
    button.label = "#{I18n.t('confirm.confirm')}(_O)"
  end

  dialog.set_position(Gtk::WindowPosition::CENTER)
  dialog.show_all

  play_warning_sound

  dialog.run
  dialog.destroy

end

# 警告音を鳴らす
def play_warning_sound
  Win32::MessageBeep(0x00000030)
end

# エラーメッセージの取得
def error_dialog(type, error)
  case type
  when :db_error
    I18n.t('error.db_error', error: error)
  when :write_error
    I18n.t('error.write_error', error: error)
  when :modify_error
    I18n.t('error.modify_error', error: error)
  when :remove_error
    I18n.t('error.remove_error', error: error)
  else
    I18n.t('error.unknown_error', error: error)
  end
end

# 警告メッセージの取得
def warning_dialog(type)
  case type
  when :empty_entry
    I18n.t('warning.empty_entry')
  when :duplicate_data
    I18n.t('warning.duplicate_data')
  when :empty_original
    I18n.t('warning.empty_original')
  when :empty_title
    I18n.t('warning.empty_title')
  when :empty_storage
    I18n.t('warning.empty_storage')
  when :empty_media
    I18n.t('warning.empty_media')
  when :empty_rip
    I18n.t('warning.empty_rip')
  when :empty_ratio
    I18n.t('warning.empty_ratio')
  when :empty_date
    I18n.t('warning.empty_date')
  when :empty_episode
    I18n.t('warning.empty_episode')
  when :empty_studio
    I18n.t('warning.empty_studio')
  when :empty_publisher
    I18n.t('warning.empty_publisher')
  when :empty_division
    I18n.t('warning.empty_division')
  end
end

# アラートメッセージの取得
def alert_dialog(type)
  case type
  when :write_success
    I18n.t('alert.write_success')
  when :modify_success
    I18n.t('alert.modify_success')
  when :remove_success
    I18n.t('alert.remove_success')
  when :anime_save
    I18n.t('anime_status.save')
  when :developing
    I18n.t('alert.developing')
  end
end

# 確認メッセージの取得
def confirm_dialog(type, parent)
  message = case type
            when :remove_confirm
              I18n.t('confirm.remove_confirm')
            when :remove_group
              I18n.t('confirm.remove_group')
            when :anime_start
              I18n.t('anime_status.start')
            when :anime_stop
              I18n.t('anime_status.stop')
            when :anime_restart
              I18n.t('anime_status.restart')
            when :anime_complete
              I18n.t('anime_status.complete')
            when :book_complete
              I18n.t('book_status.complete')
            end

  confirm = Gtk::MessageDialog.new(parent: parent, flags: :destroy_with_parent, type: :question,
                                   buttons_type: :yes_no, message: message)
  confirm.set_title(I18n.t('confirm.confirm_title'))
  confirm.set_position(Gtk::WindowPosition::CENTER)
  confirm.show_all

  play_warning_sound

  confirm
end

# 制作会社、出版社の選択
def company_selector(company_selector)
  ides = []

  company_selector.signal_connect('response') do |widget, response|
    if response == Gtk::ResponseType::OK
      param = company_selector.param

      param.each do |company|
        ides << company['id']
      end
    end
  end

  ides
end

# コンボボックスの選択
def combo_selector(arr)
  arr.each do |hash|
    hash['combo_box'].model.each do |model, path, iter|
      if iter[1] == hash['active']
        hash['combo_box'].set_active_iter(iter)
        break
      end
    end
  end
end

# ファイルのアップロード
def file_upload(img_file_name, content_type, last_id)
  path = img_path

  return nil if img_file_name.nil?

  date = file_datetime
  downcase = if img_file_name.downcase.end_with?('.png')
               '.png'
             else
               '.jpg'
             end

  FileUtils.cp(img_file_name, "#{path}#{date}#{downcase}")

  files = {}

  files['refer_tb'] = content_type
  files['refer_id'] = last_id
  files['file_name'] = File.basename("#{path}#{date}#{downcase}")

  files
end

## 推薦のための現状態の判定
# 1はコンプリ又は進行中、0は未コンプリ
def status_loop(rows)
  complete_count = 0

  rows.each do |row|
    return 0 if row['status'].nil?
    return 1 if row['status'] == 2 || row['status'] == 3

    complete_count += 1 if row['status'] == 32

  end

  if complete_count == rows.size
    1
  else
    0
  end
end

# 推薦のためのグループ状態の判定
def group_status(group_status_info)

  anime_status = group_status_info['anime']
  book_status = group_status_info['book']
  book_count = group_status_info['book_count']

  status = "　（#{I18n.t('view.unwatched')}）"

  # アニメの状態の判定
  anime_status.each_with_index do |anime, i|
    break if anime.status.nil? && (i <= 0)

    if (anime.status == 2) || (anime.status.nil? && (i > 0)) || (book_count > 0)
      status = "　（#{I18n.t('view.watching')}）"
      break
    end

    if anime.status == 4
      status = "　（#{I18n.t('view.stop_watching')}）"
      break
    end

    status = "　（#{I18n.t('view.completed')}）" if (anime.status == 32) && (anime_status.length == i + 1)
  end

  # 書籍の状態の判定
  book_status.each_with_index do |book, i|
    break if book.status.nil? && (i <= 0)

    status = "　（#{I18n.t('view.watching')}）" if book.status == 32
    status = "　（#{I18n.t('view.completed')}）" if (book.status == 32) && (book_status.length == i + 1)
  end

  status

end

# dbに使うマップの作成
def create_map(param)
  Map.new({'from_tb' => param[:from_tb],
           'from_id' => param[:from_id],
           'refer_tb' => param[:refer_tb],
           'refer_id' => param[:refer_id]})
end
