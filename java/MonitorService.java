package su.zzz.android.currencysalemonitormgn;

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

import su.zzz.android.currencysalemonitormgn.database.MonitorDbHelper;
import su.zzz.android.currencysalemonitormgn.database.MonitorDbSchema;

public class MonitorService extends IntentService {
    private static final String TAG = MonitorService.class.getSimpleName();
    public static final long POOL_INTERVAL_MS = TimeUnit.MINUTES.toMillis(1);
    public static final String ACTION_UPDATE_COURSE = "su.zzz.android.currencysalemonitormgn.UPDATE_COURSE";
    public MonitorService() {
        super(TAG);
    }
    public static Intent newIntent(Context context) {
        return new Intent(context, MonitorService.class);
    }

    @Override
    protected void onHandleIntent(@Nullable Intent intent) {
        if(!isNetworkAvailableAndConnected()){
            return;
        }
        try {
            new CourseFetcher().fetch(getApplicationContext());
            MonitorPreferences.setCourseFetchDate(getApplicationContext(), System.currentTimeMillis());
            MonitorPreferences.setCourseFetchSuccess(getApplicationContext(), true);
            sendBroadcast(new Intent(ACTION_UPDATE_COURSE));
            checkCourse();
        } catch (Exception e) {
            MonitorPreferences.setCourseFetchDate(getApplicationContext(), System.currentTimeMillis());
            MonitorPreferences.setCourseFetchSuccess(getApplicationContext(), false);
            e.printStackTrace();
        }
    }

    private boolean isNetworkAvailableAndConnected() {
        ConnectivityManager cm = (ConnectivityManager) getSystemService(CONNECTIVITY_SERVICE);
        boolean isNetworkAvailable = cm.getActiveNetworkInfo() != null;
        boolean isNetworkConnected = isNetworkAvailable && cm.getActiveNetworkInfo().isConnected();
        return isNetworkConnected;
    }

    private void checkCourse() {
        float usdExpectedCourse = MonitorPreferences.getUsdExpectedCourse(getApplicationContext());
        float eurExpectedCourse = MonitorPreferences.getEurExpectedCourse(getApplicationContext());
        float usdCourse = MonitorDbHelper.getInstance(getApplicationContext()).getMinCourse(MonitorDbSchema.CourseTable.Cols.USD);
        float eurCourse = MonitorDbHelper.getInstance(getApplicationContext()).getMinCourse(MonitorDbSchema.CourseTable.Cols.EUR);
        boolean usdAlert = MonitorPreferences.getUsdMonitorState(getApplicationContext()) && usdExpectedCourse > 0.0f && usdExpectedCourse >= usdCourse;
        boolean eurAlert = MonitorPreferences.getEurMonitorState(getApplicationContext()) && eurExpectedCourse > 0.0f && eurExpectedCourse >= eurCourse;
        if(usdAlert && eurAlert){
            showNotification("Usd: "+String.format("%.2f", usdCourse)+"; Eur: "+String.format("%.2f", eurCourse));
        } else if(usdAlert){
            showNotification("Usd: "+String.format("%.2f", usdCourse));
        } else if(eurAlert) {
            showNotification("Eur: "+String.format("%.2f", eurCourse));
        } else {
            hideNotification();
        }
    }
    private void showNotification(String text) {
        Notification notification = new NotificationCompat.Builder(this)
                .setSmallIcon(android.R.drawable.ic_popup_reminder)
                .setContentTitle(getString(R.string.app_name))
                .setContentText(text)
                .build();
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
        notificationManager.notify(0, notification);
    }
    private void hideNotification() {
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
        notificationManager.cancelAll();
    }

    public static void setServiceAlarm(Context context, boolean isOn){
        Log.i(TAG, "setServiceAlarm: "+isOn);
        Intent i = MonitorService.newIntent(context);
        PendingIntent pi = PendingIntent.getService(context, 0, i, 0);
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if(isOn){
            alarmManager.setRepeating(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime(), POOL_INTERVAL_MS, pi);
        } else {
            alarmManager.cancel(pi);
            pi.cancel();
        }
    }

    public static boolean isServiceAlarmOn(Context context){
        Intent i = newIntent(context);
        PendingIntent pi = PendingIntent.getService(context, 0, i, PendingIntent.FLAG_NO_CREATE);
        return pi != null;
    }
}
