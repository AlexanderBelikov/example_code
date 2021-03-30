package su.zzz.android.currencysalemonitormgn;

import java.util.Date;
import java.util.UUID;

public class Course {
    private UUID mUUID;
    private String mBank;
    private Date mDate;
    private float mUSD;
    private float mEUR;

    public Course(UUID UUID, String bank, Date date, float USD, float EUR) {
        mUUID = UUID;
        mDate = date;
        mBank = bank;
        mUSD = USD;
        mEUR = EUR;
    }

    public UUID getUUID() {
        return mUUID;
    }

    public String getBank() {
        return mBank;
    }

    public Date getDate() {
        return mDate;
    }

    public float getUSD() {
        return mUSD;
    }

    public float getEUR() {
        return mEUR;
    }
}
