package com.shoppingagent.android.presentation.navigation

/** Rute navigasi utama aplikasi. */
sealed class Screen(val route: String) {

    data object Agent : Screen("agent")

    data object Search : Screen("search")

    data object Watchlist : Screen("watchlist")

    data object Settings : Screen("settings")

    companion object {
        val bottomBarRoutes: List<String> = listOf(
            Agent.route,
            Search.route,
            Watchlist.route,
            Settings.route
        )
    }
}
