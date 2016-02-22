# encoding: utf-8
java_import 'android.media.MediaPlayer'
java_import 'android.net.Uri'

class SpeechListener
  def initialize(activity)
    @activity = activity
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
    reset_media_players
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

      $player_ohayo.start
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

      $player_otsukare.start
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
        unless $player_ohayo.isPlaying
          reset_media_players
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    elsif greeting == :otsukare
      loop do
        unless $player_otsukare.isPlaying
          reset_media_players
          @activity.start_ruboto_activity 'RecognizeVoiceActivity'
          break
        end
      end
    end
  end

  def reset_media_players
    $player_ohayo.reset
    $player_otsukare.reset
  end
end