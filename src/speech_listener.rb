# encoding: utf-8
java_import 'android.media.MediaPlayer'
java_import 'android.net.Uri'

class SpeechListener
  def initialize(activity)
    @activity = activity
    @context = activity.getApplicationContext

    ohayo_sound_ids = [R.raw.ohayo1, R.raw.ohayo2, R.raw.ohayo3, R.raw.ohayo4, R.raw.ohayo5, R.raw.ohayo6, R.raw.ohayo7, R.raw.ohayo8]
    otsukare_sound_ids = [R.raw.otsukare1, R.raw.otsukare2, R.raw.otsukare3, R.raw.otsukare4, R.raw.otsukare5, R.raw.otsukare6, R.raw.otsukare7, R.raw.otsukare8, R.raw.otsukare9, R.raw.otsukare10, R.raw.otsukare11, R.raw.otsukare12]

    ohayo_sound_resid = ohayo_sound_ids[rand(8)]
    otsukare_sound_resid = otsukare_sound_ids[rand(12)]

    @player_ohayo = MediaPlayer.new
    @player_otsukare = MediaPlayer.new

    prepare_greeting_player @player_ohayo, ohayo_sound_resid
    prepare_greeting_player @player_otsukare, otsukare_sound_resid
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

  def prepare_greeting_player player, greeting_resid
    greeting_uri = Uri.parse("android.resource://com.ohayoman_app/#{greeting_resid}")
    player.set_data_source(@context, greeting_uri)
    player.set_audio_stream_type(AudioManager::STREAM_DTMF)
    player.prepare
  end
end