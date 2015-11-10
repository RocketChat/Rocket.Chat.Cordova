package com.meteor.cordova.updater;

import java.util.HashSet;
import java.util.Set;

import android.net.Uri;
import android.util.Log;

/**
 * UriRemapper backed by AssetManager assets
 *
 */
public class AssetUriRemapper implements UriRemapper {
    private static final String TAG = "meteor.cordova.updater";

    final Asset assetBase;

    /**
     * If true, if a path looksLikeFile(), we will assume it is present and a file without checking. This saves a lot of
     * AssetManager calls.
     */
    private boolean assumeFilesArePresent;

    /**
     * A set of extensions that are used as the test for looksLikeFile()
     */
    static final Set<String> KNOWN_FILE_EXTENSIONS;
    static {
        KNOWN_FILE_EXTENSIONS = new HashSet<String>();

        KNOWN_FILE_EXTENSIONS.add("htm");
        KNOWN_FILE_EXTENSIONS.add("html");

        KNOWN_FILE_EXTENSIONS.add("js");

        KNOWN_FILE_EXTENSIONS.add("css");

        KNOWN_FILE_EXTENSIONS.add("map");

        KNOWN_FILE_EXTENSIONS.add("ico");
        KNOWN_FILE_EXTENSIONS.add("png");
        KNOWN_FILE_EXTENSIONS.add("jpg");
        KNOWN_FILE_EXTENSIONS.add("jpeg");
        KNOWN_FILE_EXTENSIONS.add("gif");

        KNOWN_FILE_EXTENSIONS.add("json");
    }

    public AssetUriRemapper(Asset assetBase, boolean assumeFilesArePresent) {
        this.assetBase = assetBase;
        this.assumeFilesArePresent = assumeFilesArePresent;

        if (assetBase == null) {
            throw new IllegalArgumentException();
        }
    }

    @Override
    public Remapped remapUri(Uri uri) {
        String path = uri.getPath();

        assert path.startsWith("/");
        if (path.startsWith("/")) {
            path = path.substring(1);
        }

        if (assumeFilesArePresent && looksLikeFile(path)) {
            Uri assetUri = Uri.parse("file:///android_asset/" + assetBase.path + "/" + path);
            return new Remapped(assetUri, false);
        }

        Asset asset = assetBase.find(path);
        if (asset == null) {
            // No such asset
            return null;
        }

        // Don't serve directories.
        // hasChildren is slow... so we use some heuristics first
        boolean isDirectory = false;
        if (looksLikeFile(path)) {
            Log.v(TAG, "Assuming not a directory: " + path);
        } else {
            if (asset.hasChildren()) {
                isDirectory = true;
            }
        }

        Uri assetUri = Uri.parse("file:///android_asset/" + assetBase.path + "/" + path);
        return new Remapped(assetUri, isDirectory);
    }

    // private boolean assetExists(String assetPath) {
    // InputStream is = null;
    // try {
    // is = assetManager.open(assetPath);
    // } catch (FileNotFoundException e) {
    // return false;
    // } catch (IOException e) {
    // Log.d(TAG, "Error while opening " + assetPath + "(" + e + ")");
    // return false;
    // } finally {
    // Utils.closeQuietly(is);
    // }
    // return true;
    // }

    /**
     * Checks the filename, to see if looks like a file (and not a directory)
     * 
     * Currently this is extension based; we assume there won't be folders named "something.js" (or, if there are, we
     * assume we won't load index.html from them)
     */
    private boolean looksLikeFile(String path) {
        int lastDot = path.lastIndexOf('.');
        if (lastDot == -1) {
            return false;
        }
        String extension = path.substring(lastDot + 1);
        return KNOWN_FILE_EXTENSIONS.contains(extension);
    }

}
