# encoding: utf-8
java_import 'android.os.Handler'
java_import 'android.os.Looper'
java_import 'android.net.Uri'

java_import 'java.io.InputStream'
java_import 'java.io.BufferedReader'
java_import 'java.io.InputStreamReader'
java_import 'java.lang.StringBuilder'
java_import 'java.net.URL'
java_import 'java.util.Timer'
java_import 'java.util.TimerTask'

java_import 'org.json.JSONObject'

# Services are complicated and don't really make sense unless you
# show the interaction between the Service and other parts of your
# app.
# For now, just take a look at the explanation and example in
# online:
# http://developer.android.com/reference/android/app/Service.html
class GetCurrentPrecipitationService
  def onStartCommand(intent, flags, startId)
    timer = Timer.new
    timer_task = GetCurrentPrecipitationTask.new
    timer.schedule(timer_task, 1000, 600000)

    android.app.Service::START_STICKY
  end
end

class GetCurrentPrecipitationTask < TimerTask
  def run
    get_precipitation
  end
end

private

def get_precipitation
  thread = Thread.start do
    request_url = 'http://weather.olp.yahooapis.jp/v1/place?coordinates=139.708936,35.662719&output=json&appid=dj0zaiZpPWJscmYzSDNiZUFEUiZzPWNvbnN1bWVyc2VjcmV0Jng9MmY-'
    url = URL.new(request_url)
    connection = url.openConnection

    begin
      input_stream = connection.getInputStream
      reader = BufferedReader.new(InputStreamReader.new(input_stream, "UTF-8"))
      string_builder = StringBuilder.new

      while ((line = reader.readLine()) != nil)
        string_builder.append(line)
      end
      data = string_builder.toString();
      precipitations = JSONObject.new(data).getJSONArray('Feature').getJSONObject(0).getJSONObject('Property')
                           .getJSONObject('WeatherList').getJSONArray('Weather')
      2.times do |count|
        rainfall = precipitations.getJSONObject(count).getString('Rainfall').to_i
        if rainfall != 0
          $notify_it_is_raining_player = MediaPlayer.new
          raining_voice_uri = Uri.parse("android.resource://com.ohayoman_app/#{R.raw.it_is_raining}")
          $notify_it_is_raining_player.set_data_source($context, raining_voice_uri)
          $notify_it_is_raining_player.set_audio_stream_type(AudioManager::STREAM_DTMF)
          $notify_it_is_raining_player.prepare
        else
          $notify_it_is_raining_player == nil if $notify_it_is_raining_player != nil
        end
      end
    rescue Exception
      Log.i 'MyApp', "Exception in task:\n#$!\n#{$!.backtrace.join("\n")}"
    end
  end
  thread.join
end
