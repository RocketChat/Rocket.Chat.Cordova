package com.meteor.cordova.updater;

import android.net.Uri;

public interface UriRemapper {
    /**
     * Remapped is the result, it gives a uri to remap to, and whether the uri is a directory (vs a file)
     * 
     */
    public static class Remapped {
        public final Uri uri;
        public final boolean isDirectory;

        public Remapped(Uri uri, boolean isDirectory) {
            this.uri = uri;
            this.isDirectory = isDirectory;
        }
    }

    /**
     * Tries to remap the uri
     * 
     * @param uri
     * @return remapped path for a remap, otherwise null
     */
    Remapped remapUri(Uri uri);
}
