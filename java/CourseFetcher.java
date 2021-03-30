package su.zzz.android.currencysalemonitormgn;

import android.content.Context;
import android.util.Log;
import org.xmlpull.v1.XmlPullParserException;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.ParseException;
import java.util.List;

import su.zzz.android.currencysalemonitormgn.database.*;

public class CourseFetcher {
    private static final String TAG = CourseFetcher.class.getSimpleName();
    private static final String COURSE_SOURCE_URL = "https://informer.kovalut.ru/webmaster/xml-table.php?kod=7416";

    private List getCourseList() throws IOException, XmlPullParserException, ParseException {
        URL url = new URL(COURSE_SOURCE_URL);
        List<Course> courseList = null;
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();

        try {
            InputStream stream = connection.getInputStream();
            if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                throw new IOException(connection.getResponseMessage());
            }
            courseList = new CourseXmlParser().parse(stream);
        } finally {
            connection.disconnect();
        }
        return courseList;
    }


    public boolean fetch(Context context) throws IOException, XmlPullParserException, ParseException {
        MonitorDbHelper.getInstance(context).cleanCourses();
        List<Course> courseList = getCourseList();
        if (courseList.size() == 0) {
            throw new RuntimeException("Error fetch bank courses, courseList is empty");
        }
        for (Course course:courseList) {
            MonitorDbHelper.getInstance(context).insertCourse(course);
        }
        return true;
    }
}
