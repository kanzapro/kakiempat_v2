package com.shoppingagent.android.presentation.components

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import com.shoppingagent.android.R
import com.shoppingagent.android.presentation.navigation.Screen

private data class BottomBarItem(
    val route: String,
    @StringRes val labelRes: Int,
    val icon: ImageVector
)

private val bottomBarItems = listOf(
    BottomBarItem(Screen.Agent.route, R.string.tab_agent, Icons.Filled.SmartToy),
    BottomBarItem(Screen.Search.route, R.string.tab_search, Icons.Filled.Search),
    BottomBarItem(Screen.Watchlist.route, R.string.tab_watchlist, Icons.Filled.FavoriteBorder),
    BottomBarItem(Screen.Settings.route, R.string.tab_settings, Icons.Filled.Settings)
)

/** Navigasi utama 4 tab: Agen AI, Pencarian, Watchlist, Pengaturan. */
@Composable
fun ShoppingBottomBar(
    currentRoute: String,
    onNavigate: (String) -> Unit
) {
    NavigationBar {
        bottomBarItems.forEach { item ->
            val label = stringResource(item.labelRes)
            NavigationBarItem(
                selected = currentRoute == item.route,
                onClick = { onNavigate(item.route) },
                icon = { Icon(imageVector = item.icon, contentDescription = label) },
                label = { Text(text = label) }
            )
        }
    }
}
