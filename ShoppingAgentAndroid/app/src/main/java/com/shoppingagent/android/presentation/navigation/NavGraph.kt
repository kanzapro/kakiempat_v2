package com.shoppingagent.android.presentation.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.shoppingagent.android.presentation.chat.AgentChatScreen
import com.shoppingagent.android.presentation.components.ShoppingBottomBar
import com.shoppingagent.android.presentation.search.ProductSearchScreen
import com.shoppingagent.android.presentation.settings.SettingsScreen
import com.shoppingagent.android.presentation.watchlist.WatchlistScreen

@Composable
fun ShoppingAgentNavGraph(
    viewModelFactory: ViewModelProvider.Factory,
    modifier: Modifier = Modifier
) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route ?: Screen.Agent.route

    Scaffold(
        modifier = modifier,
        bottomBar = {
            ShoppingBottomBar(
                currentRoute = currentRoute,
                onNavigate = { route ->
                    navController.navigate(route) {
                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            )
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Agent.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Agent.route) {
                AgentChatScreen(viewModelFactory = viewModelFactory)
            }
            composable(Screen.Search.route) {
                ProductSearchScreen(viewModelFactory = viewModelFactory)
            }
            composable(Screen.Watchlist.route) {
                WatchlistScreen(viewModelFactory = viewModelFactory)
            }
            composable(Screen.Settings.route) {
                SettingsScreen(viewModelFactory = viewModelFactory)
            }
        }
    }
}
