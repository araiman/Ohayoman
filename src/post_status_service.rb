# Services are complicated and don't really make sense unless you
# show the interaction between the Service and other parts of your
# app.
# For now, just take a look at the explanation and example in
# online:
# http://developer.android.com/reference/android/app/Service.html

java_import 'android.os.Handler'
java_import 'android.os.Looper'

java_import 'java.util.Timer'
java_import 'java.util.TimerTask'
java_import 'java.lang.Runnable'
java_import 'android.net.http.AndroidHttpClient'

java_import 'org.apache.http.client.entity.UrlEncodedFormEntity'
java_import 'org.apache.http.client.methods.HttpPost'
java_import 'org.apache.http.message.BasicNameValuePair'
java_import 'org.apache.http.util.EntityUtils'

class PostStatusService
  def onStartCommand intent, flags, startId
    timer = Timer.new
    timer_task = PostActiveStatusTask.new
    timer.schedule(timer_task, 1000, 180000)

    android.app.Service::START_STICKY
  end
end

class PostActiveStatusTask < TimerTask
  def run
    thread = Thread.start do
      begin
        client = AndroidHttpClient.newInstance('HttpClient')
        ohayoman_web = HttpPost.new("https://fathomless-tundra-9411.herokuapp.com/slack/status")
        ohayoman_status = BasicNameValuePair.new('status_code', '20')
        entity = UrlEncodedFormEntity.new([ohayoman_status])
        ohayoman_web.setEntity(entity)
        client.execute(ohayoman_web)
      rescue Exception
        Log.i 'MyApp', "Exception in task:\n#$!\n#{$!.backtrace.join("\n")}"
      ensure
        client.close if client
      end
    end
    thread.join
  end
end
