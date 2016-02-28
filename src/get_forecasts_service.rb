# encoding: utf-8
java_import 'android.media.AudioManager'
java_import 'android.media.MediaPlayer'
java_import 'android.os.Handler'
java_import 'android.os.Looper'
java_import 'android.net.Uri'

java_import 'java.io.InputStream'
java_import 'java.io.BufferedReader'
java_import 'java.io.InputStreamReader'
java_import 'java.lang.StringBuilder'
java_import 'java.net.URL'

java_import 'org.json.JSONObject'
# Services are complicated and don't really make sense unless you
# show the interaction between the Service and other parts of your
# app.
# For now, just take a look at the explanation and example in
# online:
# http://developer.android.com/reference/android/app/Service.html
class GetForecastsService
  def onStartCommand(intent, flags, startId)
    # HACK URLを定数管理して、展開するようにしたい
    forecast_request_url = 'http://api.openweathermap.org/data/2.5/forecast/daily?q=Shibuya&mode=json&units=metric&cnt=7&appid=87c7ae56cbdd0b581f82e2a2468e7db5'
    forecast_url = URL.new(forecast_request_url)
    forecast_connection = forecast_url.openConnection
    thread2 = Thread.start do
      begin
        forecast_input_stream = forecast_connection.getInputStream
        reader = BufferedReader.new(InputStreamReader.new(forecast_input_stream, "UTF-8"))
        forecast_string_builder = StringBuilder.new

        while ((line2 = reader.readLine()) != nil)
          forecast_string_builder.append(line2)
        end
        data2 = forecast_string_builder.toString();

        forecasts = JSONObject.new(data2).getJSONArray('list')
        today_timestamp = forecasts.getJSONObject(0).getInt('dt')
        today_datetime = Time.at(today_timestamp)
        today_weekday = today_datetime.wday

        if today_weekday != 6 #金曜以外
          precipitation = forecasts.getJSONObject(1).getJSONArray('weather').getJSONObject(0).getInt('id')
          prepare_forecasts_voice precipitation, false
        elsif today_weekday == 6 #金曜
          precipitation = forecasts.getJSONObject(3).getJSONArray('weather').getJSONObject(0).getInt('id')
          prepare_forecasts_voice precipitation, true
        else
          Log.e 'debug', '曜日を取得できなかったか、今日は平日ではありません'
        end
      rescue Exception
        Log.i 'MyApp', "Exception in task:\n#$!\n#{$!.backtrace.join("\n")}"
      end
    end
    thread2.join
    android.app.Service::START_STICKY
  end

  def prepare_forecasts_voice precipitation, isFriday
    if precipitation >= 500 && precipitation < 600
      $notify_it_will_rain_player = MediaPlayer.new
      if !isFriday
        will_rain_voice_uri = Uri.parse("android.resource://com.ohayoman_app/#{R.raw.it_will_rain_tomorrow}")
        $notify_it_will_rain_player.set_data_source($context, will_rain_voice_uri)
        $notify_it_will_rain_player.set_audio_stream_type(AudioManager::STREAM_DTMF)
        $notify_it_will_rain_player.prepare
      else
        will_rain_voice_uri = Uri.parse("android.resource://com.ohayoman_app/#{R.raw.it_will_rain_monday}")
        $notify_it_will_rain_player.set_data_source($context, will_rain_voice_uri)
        $notify_it_will_rain_player.set_audio_stream_type(AudioManager::STREAM_DTMF)
        $notify_it_will_rain_player.prepare
      end
    elsif precipitation >= 600 && precipitation < 700
      $notify_it_will_snow_player = MediaPlayer.new
      if !isFriday
        will_snow_voice_uri = Uri.parse("android.resource://com.ohayoman_app/#{R.raw.it_will_snow_tomorrow}")
        $notify_it_will_snow_player.set_data_source($context, will_snow_voice_uri)
        $notify_it_will_snow_player.set_audio_stream_type(AudioManager::STREAM_DTMF)
        $notify_it_will_snow_player.prepare
      else
        will_snow_voice_uri = Uri.parse("android.resource://com.ohayoman_app/#{R.raw.it_will_snow_monday}")
        $notify_it_will_snow_player.set_data_source($context, will_snow_voice_uri)
        $notify_it_will_snow_player.set_audio_stream_type(AudioManager::STREAM_DTMF)
        $notify_it_will_snow_player.prepare
      end
    elsif precipitation != nil
      $notify_it_will_rain_player = nil if $notify_it_will_rain_player != nil
      $notify_it_will_snow_player = nil if $notify_it_will_snow_player != nil
    end
  end
end
