package com.meteor.cordova.updater;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;

import com.meteor.cordova.updater.UriRemapper.Remapped;

import android.content.Context;
import android.content.res.AssetManager;
import android.net.Uri;
import android.util.Log;

public class CordovaUpdatePlugin extends CordovaPlugin {
    private static final String TAG = "meteor.cordova.updater";

    private static final String DEFAULT_HOST = "meteor.local";
    private static final String DEFAULT_PAGE = "index.html";

    final Set<String> hosts = new HashSet<String>();
    final Set<String> schemes = new HashSet<String>();
    private List<UriRemapper> remappers = new ArrayList<UriRemapper>();

    private String wwwRoot;
    private String cordovajsRoot;

    Asset assetRoot;

    public CordovaUpdatePlugin() {
        this.hosts.add(DEFAULT_HOST);
        this.schemes.add("http");
        this.schemes.add("https");
    }

    /**
     * Overrides uri resolution.
     * 
     * Implements remapping, including adding default files (index.html) for directories
     */
    @Override
    public Uri remapUri(Uri uri) {
        Log.v(TAG, "remapUri " + uri);

        String scheme = uri.getScheme();
        if (scheme == null || !schemes.contains(scheme)) {
            Log.d(TAG, "Scheme is not intercepted: " + scheme);
            return uri;
        }
        String host = uri.getHost();
        if (host == null || !hosts.contains(host)) {
            Log.d(TAG, "Host is not intercepted: " + host);
            return uri;
        }

        Remapped remapped = remap(uri);

        // Hack needed because we don't respect the URL-path mappings in program.json
        // and these actually differ after the 1.2 build tool changes.
        // So for now we just try again with /app in front of the path.
        if (remapped == null) {
          Uri altUri = uri.buildUpon().path("app" + uri.getPath()).build();
          remapped = remap(altUri);
        }

        if (remapped == null) {
            // If e.g. /lists/doesnotexist is not found, we will try to serve /index.html
            // XXX: This needs a double-check, to make sure it works the same as ./packages/webapp/webapp_server.js
            // (if uri was /index.html, we will recheck it, but not a big deal)
            Uri defaultPage = uri.buildUpon().path(DEFAULT_PAGE).build();
            Log.d(TAG, "Unable to find " + uri + ", will try " + defaultPage);
            remapped = remap(defaultPage);
        }

        if (remapped != null) {
            if (remapped.isDirectory) {
                Log.d(TAG, "Found asset, but was directory: " + remapped.uri);
            } else {
                Log.d(TAG, "Remapping to " + remapped.uri);
                return remapped.uri;
            }
        }

        // Serve defaultPage if directory
        if (remapped != null && remapped.isDirectory) {
            Uri defaultPage = Uri.withAppendedPath(uri, DEFAULT_PAGE);

            remapped = remap(defaultPage);
            if (remapped != null) {
                if (remapped.isDirectory) {
                    Log.d(TAG, "Found asset, but was directory: " + remapped.uri);
                } else {
                    Log.d(TAG, "Remapping to " + remapped.uri);
                    return remapped.uri;
                }
            }
        }

        // No remapping; return unaltered
        Log.d(TAG, "No remapping for " + uri);
        return uri;
    }

    /**
     * Helper function that tries all the remappers, to find the first that can remap a Uri
     * 
     * @param uri
     * @return
     */
    private Remapped remap(Uri uri) {
        List<UriRemapper> remappers;
        synchronized (this) {
            remappers = this.remappers;
        }

        for (UriRemapper remapper : remappers) {
            Remapped remapped = remapper.remapUri(uri);
            if (remapped != null) {
                return remapped;
            }
        }
        return null;
    }

    private static final String ACTION_START_SERVER = "startServer";
    private static final String ACTION_SET_LOCAL_PATH = "setLocalPath";
    private static final String ACTION_GET_CORDOVAJSROOT = "getCordovajsRoot";

    /**
     * Entry-point for JS calls from Cordova
     */
    @Override
    public boolean execute(String action, JSONArray inputs, CallbackContext callbackContext) throws JSONException {
        try {
            if (ACTION_START_SERVER.equals(action)) {
                String wwwRoot = inputs.getString(0);
                String cordovaRoot = inputs.getString(1);

                String result = startServer(wwwRoot, cordovaRoot, callbackContext);

                callbackContext.success(result);

                return true;
            } else if (ACTION_SET_LOCAL_PATH.equals(action)) {
                String wwwRoot = inputs.getString(0);

                setLocalPath(wwwRoot, callbackContext);

                callbackContext.success();
                return true;
            } else if (ACTION_GET_CORDOVAJSROOT.equals(action)) {
                String result = getCordovajsRoot(callbackContext);

                callbackContext.success(result);

                return true;
            } else {
                Log.w(TAG, "Invalid action passed: " + action);
                PluginResult result = new PluginResult(Status.INVALID_ACTION);
                callbackContext.sendPluginResult(result);
            }
        } catch (Exception e) {
            Log.w(TAG, "Caught exception during execution: " + e);
            String message = e.toString();
            callbackContext.error(message);
        }

        return true;
    }

    /**
     * JS-called function, called after a hot-code-push
     * 
     * @param wwwRoot
     * @param callbackContext
     */
    private void setLocalPath(String wwwRoot, CallbackContext callbackContext) {
        Log.w(TAG, "setLocalPath(" + wwwRoot + ")");

        this.updateLocations(wwwRoot, this.cordovajsRoot);
    }

    /**
     * Helper function that sets up the resolver ordering
     * 
     * @param wwwRoot
     * @param cordovajsRoot
     */
    private void updateLocations(String wwwRoot, String cordovajsRoot) {
        synchronized (this) {
            UriRemapper appRemapper = null;

            File fsRoot;
            // XXX: This is very iOS specific
            if (wwwRoot.startsWith("../../Documents/meteor")) {
                Context ctx = cordova.getActivity().getApplicationContext();
                fsRoot = new File(ctx.getApplicationInfo().dataDir, wwwRoot.substring(6));
            } else {
                fsRoot = new File(wwwRoot);
            }
            if (fsRoot.exists()) {
                appRemapper = new FilesystemUriRemapper(fsRoot);
            } else {
                Log.w(TAG, "Filesystem root not found; falling back to assets: " + wwwRoot);

                Asset wwwAsset = getAssetRoot().find(Utils.stripPrefix(wwwRoot, "/android_asset/www/"));
                if (wwwAsset == null) {
                    Log.w(TAG, "Could not find asset: " + wwwRoot + ", default to asset root");
                    wwwAsset = getAssetRoot();
                }
                appRemapper = new AssetUriRemapper(wwwAsset, false);
            }

            // XXX HACKHACK serve cordova.js from the containing folder
            Asset cordovaAssetBase = getAssetRoot().find(Utils.stripPrefix(cordovajsRoot, "/android_asset/www/"));
            if (cordovaAssetBase == null) {
                Log.w(TAG, "Could not find asset: " + cordovajsRoot + ", default to www root");
                cordovaAssetBase = getAssetRoot();
            }
            final AssetUriRemapper cordovaRemapper = new AssetUriRemapper(cordovaAssetBase, true);

            UriRemapper cordovaUriRemapper = new UriRemapper() {
                @Override
                public Remapped remapUri(Uri uri) {
                    String path = uri.getPath();

                    // if ([path isEqualToString:@"/cordova.js"] || [path isEqualToString:@"/cordova_plugins.js"] ||
                    // [path hasPrefix:@"/plugins/"])
                    // return [[METEORCordovajsRoot stringByAppendingPathComponent:path] stringByStandardizingPath];
                    if (path.equals("/cordova.js") || path.equals("/cordova_plugins.js")
                            || path.startsWith("/plugins/")) {
                        Log.v(TAG, "Detected cordova URI: " + uri);
                        Remapped remapped = cordovaRemapper.remapUri(uri);
                        if (remapped == null) {
                            Log.w(TAG, "Detected cordova URI, but resource remap failed: " + uri);
                        }
                        return remapped;
                    }

                    return null;
                }
            };

            List<UriRemapper> remappers = new ArrayList<UriRemapper>();
            remappers.add(cordovaUriRemapper);
            remappers.add(appRemapper);

            this.wwwRoot = wwwRoot;
            this.cordovajsRoot = cordovajsRoot;
            this.remappers = remappers;
        }
    }

    private Asset getAssetRoot() {
        if (this.assetRoot == null) {
            Context ctx = cordova.getActivity().getApplicationContext();
            AssetManager assetManager = ctx.getResources().getAssets();

            this.assetRoot = new Asset(assetManager, "www");

            // For debug
            // this.assetRoot.dump();
        }
        return this.assetRoot;
    }

    /**
     * JS-called function, that returns cordovajsRoot as set previously
     * 
     * @param callbackContext
     * @return
     */
    private String getCordovajsRoot(CallbackContext callbackContext) {
        Log.w(TAG, "getCordovajsRoot");

        return this.cordovajsRoot;
    }

    /**
     * JS-called function, that starts the url interception
     * 
     * @param callbackContext
     * @return
     */
    private String startServer(String wwwRoot, String cordovaRoot, CallbackContext callbackContext)
            throws JSONException {
        Log.w(TAG, "startServer(" + wwwRoot + "," + cordovaRoot + ")");

        this.updateLocations(wwwRoot, cordovaRoot);

        return "http://" + DEFAULT_HOST;
    }

}
