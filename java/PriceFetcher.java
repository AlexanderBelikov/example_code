package su.zzz.pricemonitor;

import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class PriceFetcher {
    private static final String TAG = PriceFetcher.class.getSimpleName();
    public int fetchPrice() {
        int price = 0;
        Document doc = null;
        try {
            doc = Jsoup.connect("https://www.dochkisinochki.ru/icatalog/products/355582/").timeout(10000).get();
        } catch (IOException ioe) {
            Log.e(TAG, "fetchPrice: Failed to fetch price: ", ioe);
        }
        Elements scripts = doc.select("script[type=text/javascript]");
        Pattern pattern = Pattern.compile("var oRrData = (\\{.*?\\});", Pattern.DOTALL);
        Matcher matcher;
        for(Element script:scripts){
            matcher = pattern.matcher(script.html());
            if(matcher.find()){
                try {
                    JSONObject jsonBody = new JSONObject(matcher.group(1));
                    price = jsonBody.getInt("price");
                } catch (JSONException je) {
                    Log.e(TAG, "fetchPrice: Failed to parse json: ", je);
                }
                break;
            }
        }
        Log.i(TAG, "fetchPrice: price: "+price);
        return price;
    }
}
