# encoding: utf-8
require 'ruboto/activity'
require 'ruboto/util/toast'

java_import 'android.speech.RecognizerIntent'
java_import 'android.speech.SpeechRecognizer'
java_import 'android.speech.RecognitionListener'
java_import 'android.content.Intent'
java_import 'android.media.MediaPlayer'
java_import 'android.media.AudioManager'
java_import 'android.net.Uri'
java_import 'android.util.Log'

class RecognizeVoiceActivity
  def on_create(bundle)
    super
    set_title 'Recognize Speeches'

    Log.v 'debug', 'RecognizeVoiceActivity created'
    context = getApplicationContext
    start_recognize_voice(context)
    Log.v 'debug', 'Recognizing voice started'
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
    @speech_recognizer.start_listening(intent)
  end
end

class SpeechListener
  def initialize(activity)
    @activity = activity
    @context = activity.getApplicationContext
  end

  def hashCode
    hash
  end

  def onBeginningOfSpeech
    Log.v 'debug', 'onBeginningOfSpeech'
  end

  def onBufferReceived(_buffer)
    Log.v 'debug', 'onBufferReceived'
  end

  def onEndOfSpeech
    Log.v 'debug', 'onEndOfSpeech'
  end

  def onError(error)
    context = @activity.getApplicationContext
    Log.v 'debug', "context is #{context}"
    Log.v 'debug', 'error occured'
    Log.v 'debug', "error code is #{error}"
    # REVIEW スタイルガイドに忠実に従えば、if文で改行すべきだが、これくらいなら改行しない方が読みやすいのでは？
    @activity.start_ruboto_activity 'RecognizeVoiceActivity' if error == 6 || error == 7
  end

  def onEvent(_event_type, _params)
    Log.v 'debug', 'onEvent'
  end

  def onPartialResults(_partial_results)
    Log.v 'debug', 'onPartialResults'
  end

  def onReadyForSpeech(_params)
    Log.v 'debug', 'onReadyForSpeech'
  end

  # HACK 複雑すぎるのでもっと読みやすくする。コードを1個にまとめよう。
  def onResults(results)
    result = results.get_string_array_list(SpeechRecognizer::RESULTS_RECOGNITION)

    if result[0] == 'おはよう' \
      || result[0] == 'おはよー' \
      || result[0] == 'おはよ' \
      || result[0] == 'おはようございます' \
      || result[0] == 'はようございます' \
      || result[0] == 'おはよう ございます'
      @player = MediaPlayer.create(@context, R.raw.ohayo1)
      audio_manager = @context.getSystemService(Context::AUDIO_SERVICE)
      audio_manager.requestAudioFocus(@listener, AudioManager::STREAM_MUSIC, AudioManager::AUDIOFOCUS_GAIN)
      @player.start

      loop do
        Log.v 'debug', 'loop'
        unless @player.isPlaying
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    end

    if result[0] == 'こんにちは' \
      || result[0] == 'こんにちわ' \
      || result[0] == 'こんちは' \
      || result[0] == 'こんちわ'
      @player = MediaPlayer.create(self, R.raw.ohayo1)
      context = getApplicationContext
      audio_manager = context.getSystemService(Context::AUDIO_SERVICE)
      audio_manager.requestAudioFocus(@listener, AudioManager::STREAM_MUSIC, AudioManager::AUDIOFOCUS_GAIN)
      @player.start

      loop do
        unless @player.isPlaying
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    end

    if result[0] == 'お疲れ様です' \
      || result[0] == 'お疲れさまです' \
      || result[0] == 'おつかれさまです' \
      || result[0] == 'お疲れ' \
      || result[0] == 'おつかれ' \
      || result[0] == 'お先に失礼します' \
      || result[0] == '咲いています' \
      || result[0] == 'します' \
      || result[0] == '先にします'
      @player = MediaPlayer.create(@context, R.raw.otsukare1)
      audio_manager = @context.getSystemService(Context::AUDIO_SERVICE)
      audio_manager.requestAudioFocus(@listener, AudioManager::STREAM_MUSIC, AudioManager::AUDIOFOCUS_GAIN)
      @player.start

      loop do
        unless @player.isPlaying
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    end
  end

  def onRmsChanged(_rmsdB)
    Log.v 'debug', 'onRmsChanged'
  end
end

class AudioFocus
  def onAudioFocusChange(_focusChange)
    nil
  end

  def toString
    self.class.to_s
  end
end
