# encoding: utf-8
require 'ruboto/activity'
require 'ruboto/util/toast'
require 'ruboto/widget'

java_import 'android.speech.RecognizerIntent'
java_import 'android.speech.SpeechRecognizer'
java_import 'android.speech.RecognitionListener'
java_import 'android.content.Intent'
java_import 'android.media.MediaPlayer'
java_import 'android.media.AudioManager'
java_import 'android.net.Uri'
java_import 'android.util.Log'
java_import 'android.net.ConnectivityManager'
java_import 'android.net.http.AndroidHttpClient'
java_import 'android.view.Window'

java_import 'org.apache.http.client.entity.UrlEncodedFormEntity'
java_import 'org.apache.http.client.methods.HttpPost'
java_import 'org.apache.http.message.BasicNameValuePair'
java_import 'org.apache.http.util.EntityUtils'

ruboto_import_widgets :LinearLayout, :TextView, :ImageView

class RecognizeVoiceActivity
  def onCreate(bundle)
    super
    build_ui

    @context = getApplicationContext
    connectivity_manager = @context.get_system_service(Context::CONNECTIVITY_SERVICE)
    network = connectivity_manager.getActiveNetworkInfo
    if network
      is_online = network.is_connected_or_connecting
      if is_online
        if $is_first_launch == nil
          thread = Thread.start do
            begin
              notify_slack_ohayoman_status '10'
            rescue Exception
              Log.i 'MyApp', "Exception in task:\n#$!\n#{$!.backtrace.join("\n")}"
            ensure
              @client.close if @client
            end
          end
          thread.join
          $is_first_launch = false
          @context.start_service(Intent.new(self, $package.PostStatusService.java_class))
        end
        start_recognize_voice(@context)
      else
        setContentView(text_view :text => '端末がオフラインです。ネットワークを有効にするか、ネットワークが有効なアクセスポイントに変更して、再起動してください。')
      end
    else
      setContentView(text_view :text => '端末がオフラインです。インターネットに接続して、再起動してください。')
    end
  end

  def onDestroy
    super
    if $is_first_destroy == nil
      thread = Thread.start do
        begin
          notify_slack_ohayoman_status '11'
          $is_first_destroy = false
        rescue Exception
          Log.i 'MyApp', "Exception in task:\n#$!\n#{$!.backtrace.join("\n")}"
        ensure
          @client.close if @client
        end
      end
      thread.join
    end
  end

  def start_recognize_voice(context)
    recognition_listner = SpeechListener.new(self)
    @speech_recognizer = SpeechRecognizer.create_speech_recognizer(context)
    @speech_recognizer.set_recognition_listener(recognition_listner)
    intent = Intent.new(RecognizerIntent::ACTION_RECOGNIZE_SPEECH)
    intent.putExtra(RecognizerIntent::EXTRA_LANGUAGE, 'ja_JP')
    intent.putExtra(RecognizerIntent::EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent::LANGUAGE_MODEL_FREE_FORM)
    intent.putExtra(RecognizerIntent::EXTRA_PROMPT, 'Please Speech')

    # 音声のMute,unMute処理を繰り返し行うには、Activity全体で1つのAudioManagerを使わなければいけないルール。
    # リスナーでも同じManagerを使えるよう，Global変数にしている．
    $audio_manager = @context.getSystemService(Context::AUDIO_SERVICE)
    $audio_manager.setStreamMute(AudioManager::STREAM_MUSIC, true)

    @speech_recognizer.start_listening(intent)
  end


  def notify_slack_ohayoman_status status
    @client = AndroidHttpClient.newInstance('HttpClient')
    ohayoman_web = HttpPost.new("https://fathomless-tundra-9411.herokuapp.com/slack/status")
    ohayoman_status = BasicNameValuePair.new('status_code', status)
    entity = UrlEncodedFormEntity.new([ohayoman_status])
    ohayoman_web.setEntity(entity)
    @client.execute(ohayoman_web)
  end

  def build_ui
    self.requestWindowFeature(Window::FEATURE_NO_TITLE)
    self.content_view =
        linear_layout :padding => [130, 100, 130, 0], :backgroundColor => 0xffffffff do
          image_view  :image_resource => $package::R.drawable.ohayogozaimax_face_starting_up,
                      :layout => {:width => :wrap_content, :height => :wrap_content}
        end
  end
end

class SpeechListener
  def initialize(activity)
    @activity = activity
    @context = activity.getApplicationContext

    ohayo_sound_ids = [R.raw.ohayo1, R.raw.ohayo2, R.raw.ohayo3, R.raw.ohayo4, R.raw.ohayo5, R.raw.ohayo6, R.raw.ohayo7, R.raw.ohayo8]
    otsukare_sound_ids = [R.raw.otsukare1, R.raw.otsukare2, R.raw.otsukare3, R.raw.otsukare4, R.raw.otsukare5, R.raw.otsukare6, R.raw.otsukare7, R.raw.otsukare8, R.raw.otsukare9, R.raw.otsukare10, R.raw.otsukare11, R.raw.otsukare12]

    ohayo_sound = ohayo_sound_ids[rand(8)]
    otsukare_sound = otsukare_sound_ids[rand(12)]

    @player_ohayo = MediaPlayer.create(@context, ohayo_sound)
    @player_otsukare = MediaPlayer.create(@context, otsukare_sound)
  end

  def hashCode
    hash
  end

  def onBeginningOfSpeech
  end

  def onBufferReceived(_buffer)
  end

  def onEndOfSpeech
  end

  def onError(error)
    # REVIEW スタイルガイドに忠実に従えば、if文で改行すべきだが、これくらいなら改行しない方が読みやすいのでは？
    @activity.start_ruboto_activity 'RecognizeVoiceActivity'
  end

  def onEvent(_event_type, _params)
  end

  def onPartialResults(_partial_results)
  end

  def onReadyForSpeech(_params)
  end

  def onResults(results)
    result = results.get_string_array_list(SpeechRecognizer::RESULTS_RECOGNITION)

    # TODO 挨拶のバリエーションを増やした時に、各挨拶の最後の数字がランダムで変わるように変更
    if result[0] == 'おはよう' \
      || result[0] == 'おはよー' \
      || result[0] == 'おはよ' \
      || result[0] == 'おはようございます' \
      || result[0] == 'はようございます' \
      || result[0] == 'おはよう ございます'

      @player_ohayo.start
      continue_recognizing_voice :ohayo
    elsif result[0] == 'お疲れ様です' \
      || result[0] == 'お疲れさまです' \
      || result[0] == 'おつかれさまです' \
      || result[0] == 'お疲れ' \
      || result[0] == 'おつかれ' \
      || result[0] == 'お先に失礼します' \
      || result[0] == '咲いています' \
      || result[0] == 'します' \
      || result[0] == '先にします'

      @player_otsukare.start
      continue_recognizing_voice :otsukare
    else
      @activity.start_ruboto_activity 'RecognizeVoiceActivity'
    end
  end

  def onRmsChanged(_rmsdB)
  end

  def continue_recognizing_voice greeting
    if greeting == :ohayo
      loop do
        unless @player_ohayo.isPlaying
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    elsif greeting == :otsukare
      loop do
        unless @player_otsukare.isPlaying
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    end
  end
end

