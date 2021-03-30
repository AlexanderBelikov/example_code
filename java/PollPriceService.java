package su.zzz.pricemonitor;

import android.app.AlarmManager;
import android.app.IntentService;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.os.SystemClock;
import android.support.annotation.Nullable;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.NotificationManagerCompat;
import android.util.Log;

import java.util.concurrent.TimeUnit;

public class PollPriceService extends IntentService {
    private static final String TAG = PollPriceService.class.getSimpleName();
    private static final long POOL_INTERVAL_MS = TimeUnit.HOURS.toMillis(1);

    public static Intent newIntent(Context context){
        return new Intent(context, PollPriceService.class);
    }

    public PollPriceService() {
        super(TAG);
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        int price = new PriceFetcher().fetchPrice();
        int last_price = PricePreferences.getPrice(this);
        if(price != last_price){
            PricePreferences.setPrice(this, price);
            Notification notification = new NotificationCompat.Builder(this)
                    .setTicker("New car seat price: "+String.valueOf(price))
                    .setSmallIcon(android.R.drawable.star_big_on)
                    .setContentTitle("New car seat price: "+String.valueOf(price))
                    .setContentText("Last car seat price: "+String.valueOf(last_price))
                    .build();
            NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(this);
            notificationManagerCompat.notify(0, notification);
        }
    }
    public static void setServiceAlarm(Context context, boolean isOn){
        Intent i = PollPriceService.newIntent(context);
        PendingIntent pi = PendingIntent.getService(context, 0, i, 0);
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if(isOn){
          alarmManager.setRepeating(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime(), POOL_INTERVAL_MS, pi);
        } else {
            alarmManager.cancel(pi);
            pi.cancel();
        }
    }

    private boolean isNetworkAvaiableAndConnected(){
        ConnectivityManager cm = (ConnectivityManager)getSystemService(CONNECTIVITY_SERVICE);
        boolean isNetworkAvaiable = cm.getActiveNetworkInfo() != null;
        boolean isNetworkConnected = isNetworkAvaiable && cm.getActiveNetworkInfo().isConnected();
        return isNetworkConnected;
    }

    public static boolean isServiceAlarmOn(Context context){
        Intent i = PollPriceService.newIntent(context);
        PendingIntent pi = PendingIntent.getService(context, 0, i, PendingIntent.FLAG_NO_CREATE);
        return pi != null;
    }
}
