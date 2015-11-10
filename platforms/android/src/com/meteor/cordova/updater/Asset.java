package com.meteor.cordova.updater;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.content.res.AssetManager;
import android.util.Log;

/**
 * Like File, but for an Asset.
 * 
 * The asset API is really slow; so we try to cache/avoid lookups.
 */
public class Asset {
    private static final String TAG = "meteor.cordova.updater";

    final Cache cache;
    final String name;
    final String path;

    static class Cache {
        final AssetManager assetManager;
        final Map<String, List<Asset>> contents = new HashMap<String, List<Asset>>();

        public Cache(AssetManager assetManager) {
            this.assetManager = assetManager;
        }

        public Asset findAsset(String parentPath, String name) {
            List<Asset> children = listAssets(parentPath.toString());
            for (Asset child : children) {
                if (child.name.equals(name)) {
                    return child;
                }
            }
            return null;
        }

        public List<Asset> listAssets(String path) {
            List<Asset> assets = this.contents.get(path);
            if (assets == null) {
                String[] assetNames = null;
                try {
                    // This call is slow, so log it
                    Log.d(TAG, "Doing assetManager list on " + path);
                    assetNames = assetManager.list(path);
                } catch (IOException e) {
                    Log.w(TAG, "Error listing assets at " + path, e);
                }
                if (assetNames == null || assetNames.length == 0) {
                    assets = Collections.emptyList();
                } else {
                    assets = new ArrayList<Asset>(assetNames.length);
                    for (String assetName : assetNames) {
                        String childPath = (path.length() != 0) ? (path + "/" + assetName) : assetName;
                        assets.add(new Asset(this, assetName, childPath));
                    }
                }
                this.contents.put(path, assets);
            }

            return assets;
        }
    }

    /**
     * Private constructor for child assets
     * 
     * @param cache
     * @param name
     * @param path
     */
    private Asset(Cache cache, String name, String path) {
        this.cache = cache;
        this.name = name;
        this.path = path;
        assert !path.endsWith("/");
    }

    /**
     * Constructor for root asset
     */
    public Asset(AssetManager assetManager, String path) {
        this.cache = new Cache(assetManager);
        this.name = null;
        this.path = path;
        assert !path.endsWith("/");
    }

    public boolean hasChildren() {
        return !cache.listAssets(this.path).isEmpty();
    }

    public boolean exists(String path) {
        return find(path) != null;
    }

    public Asset find(String relativePath) {
        if (relativePath == null || relativePath.isEmpty()) {
            return this;
        }

        String path = this.path + "/" + relativePath;
        String[] pathTokens = path.split("/");

        // The last non-empty token is the name
        String name = null;
        int end = pathTokens.length - 1;
        while (end >= 0) {
            String pathToken = pathTokens[end];
            if (!pathToken.isEmpty()) {
                name = pathToken;
                break;
            }
            end--;
        }
        if (name == null) {
            Log.w(TAG, "Asset find on empty path: " + path);
            return null;
        }

        StringBuilder parentPath = new StringBuilder();
        for (int i = 0; i < end; i++) {
            String pathToken = pathTokens[i];
            if (pathToken.length() == 0) {
                // Ignore empty bits (either a leading slash, or a double slash)
                continue;
            }
            if (parentPath.length() != 0) {
                parentPath.append("/");
            }
            parentPath.append(pathToken);
        }

        return cache.findAsset(parentPath.toString(), name);
    }
}
