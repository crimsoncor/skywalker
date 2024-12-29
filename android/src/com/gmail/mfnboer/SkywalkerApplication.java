// Copyright (C) 2023 Michel de Boer
// License: GPLv3

package com.gmail.mfnboer;

import org.qtproject.qt.android.bindings.QtApplication;

import android.app.Application;
import android.content.Context;
import android.util.Log;
import androidx.work.Configuration;

public class SkywalkerApplication extends QtApplication implements Configuration.Provider {
    private static final String LOGTAG = "SkywalkerApplication";

    private static Application sApplication = null;

    @Override
    public void onCreate() {
        super.onCreate();
        sApplication = this;
    }

    @Override
    public Configuration getWorkManagerConfiguration() {
        Log.d(LOGTAG, "Get work manager configuration");

        return new Configuration.Builder()
                .setDefaultProcessName("com.gmail.mfnboer.skywalker:work_manager")
                .build();
    }

    public static Context getContext() {
        return sApplication.getApplicationContext();
    }
}
