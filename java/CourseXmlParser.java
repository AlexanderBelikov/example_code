package su.zzz.android.currencysalemonitormgn;

import android.util.Log;
import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.IOException;
import java.io.InputStream;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;

public class CourseXmlParser {
    private static final String TAG = CourseXmlParser.class.getSimpleName();
    private static final String ns = null;

    // Parse InpurStream Xml. Read elements Bank under Actual_Rates, and return Course ArrayList.
    public List parse(InputStream stream) throws XmlPullParserException, IOException, ParseException {
        List<Course> courseList = new ArrayList<>();

        try {
            XmlPullParser parser = Xml.newPullParser();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(stream, null);
            parser.nextTag();

            parser.require(XmlPullParser.START_TAG, null, "Exchange_Rates");
            while (parser.next() != XmlPullParser.END_TAG){
                if(parser.getEventType() != XmlPullParser.START_TAG){
                    continue;
                }
                if(parser.getName().equalsIgnoreCase("Actual_Rates")) {
                    while (parser.next() != XmlPullParser.END_TAG) {
                        if (parser.getEventType() != XmlPullParser.START_TAG) {
                            continue;
                        }
                        courseList.add(parseBankCourse(parser));
                    }
                } else {
                    skip(parser);
                }
            }
        } finally {
            stream.close();
        }
        return courseList;
    }
    // Parse XmlPullParser, return Bank Course
    private Course parseBankCourse(XmlPullParser parser) throws IOException, XmlPullParserException, ParseException {
        String bankName = null;
        Date courseDate = null;
        float courseUsdSell = 0.0f;
        float courseEurSell = 0.0f;

        SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy HH:mm");

        parser.require(XmlPullParser.START_TAG, null, "Bank");
        while (parser.next() != XmlPullParser.END_TAG){
            if(parser.getEventType() != XmlPullParser.START_TAG){
                continue;
            }
            String name = parser.getName();
            switch (name) {
                case "Name" :
                    bankName = readText(parser);
                    break;
                case "ChangeTime" :
                    courseDate = sdf.parse(readText(parser));
                    break;
                case "USD" :
                    courseUsdSell = parseSellPrice(parser);
                    break;
                case "EUR" :
                    courseEurSell = parseSellPrice(parser);
                    break;
                default:
                    skip(parser);
            }
        }
        return new Course(UUID.randomUUID(), bankName, courseDate, courseUsdSell, courseEurSell);
    }
    // get sell price
    private float parseSellPrice(XmlPullParser parser) throws IOException, XmlPullParserException {
        String price = null;
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) {
                continue;
            }
            String name = parser.getName();
            if (name.equals("Sell")) {
                price = readText(parser);
            } else {
                skip(parser);
            }
        }
        return Float.valueOf(price.replace(',','.'));
    }
    private String readText(XmlPullParser parser) throws IOException, XmlPullParserException {
        String result = "";
        if (parser.next() == XmlPullParser.TEXT) {
            result = parser.getText();
            parser.nextTag();
        }
        return result;
    }
    private void skip(XmlPullParser parser) throws XmlPullParserException, IOException {
        if (parser.getEventType() != XmlPullParser.START_TAG) {
            throw new IllegalStateException();
        }
        int depth = 1;
        while (depth != 0) {
            switch (parser.next()) {
                case XmlPullParser.END_TAG:
                    depth--;
                    break;
                case XmlPullParser.START_TAG:
                    depth++;
                    break;
            }
        }
    }
}
