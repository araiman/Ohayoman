# encoding: utf-8
require 'ruboto/activity'
require 'ruboto/util/toast'
require 'ruboto/widget'
require_relative 'speech_listener.rb'

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
    if $speech_recognizer == nil
      recognition_listner = SpeechListener.new(self)
      $speech_recognizer = SpeechRecognizer.create_speech_recognizer(context)
      $speech_recognizer.set_recognition_listener(recognition_listner)

      $recognizing_voice_intent = Intent.new(RecognizerIntent::ACTION_RECOGNIZE_SPEECH)
      $recognizing_voice_intent.putExtra(RecognizerIntent::EXTRA_LANGUAGE, 'ja_JP')
      $recognizing_voice_intent.putExtra(RecognizerIntent::EXTRA_LANGUAGE_MODEL,
                                         RecognizerIntent::LANGUAGE_MODEL_FREE_FORM)
    end
    # 音声のMute,unMute処理を繰り返し行うには、Activity全体で1つのAudioManagerを使わなければいけないルール。
    # リスナーでも同じManagerを使えるよう，Global変数にしている．
    $audio_manager = @context.getSystemService(Context::AUDIO_SERVICE)
    $audio_manager.setStreamMute(AudioManager::STREAM_SYSTEM, true)

    $speech_recognizer.start_listening($recognizing_voice_intent)
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
