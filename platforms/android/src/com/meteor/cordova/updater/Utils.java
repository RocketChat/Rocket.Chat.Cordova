package com.meteor.cordova.updater;

import java.io.Closeable;
import java.io.IOException;

import android.util.Log;

public class Utils {
    private static final String TAG = "meteor.cordova.updater";

    /**
     * Close, logging exceptions but not throwing them
     * 
     * @param closeable
     */
    public static void closeQuietly(Closeable closeable) {
        if (closeable == null) {
            return;
        }
        try {
            closeable.close();
        } catch (IOException e) {
            Log.w(TAG, "Error closing: " + closeable, e);
        }
    }

    /**
     * Strings the string without the prefix, if the prefix is present.
     * 
     * If the prefix is not present, just returns the string as-is
     * 
     * @param s
     * @param prefix
     * @return
     */
    public static String stripPrefix(String s, String prefix) {
        if (s.startsWith(prefix)) {
            return s.substring(prefix.length());
        }
        return s;
    }

}
