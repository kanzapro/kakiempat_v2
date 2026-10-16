package com.shoppingagent.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.shoppingagent.android.core.di.ViewModelFactory
import com.shoppingagent.android.core.model.UserPreferences
import com.shoppingagent.android.core.ui.theme.ShoppingAgentTheme
import com.shoppingagent.android.presentation.navigation.ShoppingAgentNavGraph

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val container = (application as ShoppingAgentApplication).container
        val viewModelFactory = ViewModelFactory(container)

        setContent {
            val preferences by container.preferencesDataStore.preferences
                .collectAsStateWithLifecycle(initialValue = UserPreferences())

            ShoppingAgentTheme(
                themeMode = preferences.themeMode,
                dynamicColor = preferences.dynamicColor
            ) {
                ShoppingAgentNavGraph(viewModelFactory = viewModelFactory)
            }
        }
    }
}
