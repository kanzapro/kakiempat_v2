package com.shoppingagent.android

import android.app.Application
import com.shoppingagent.android.core.di.AppContainer

/**
 * Entry point aplikasi: membuat [AppContainer] sekali per proses.
 */
class ShoppingAgentApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
