package com.ultrawork.notes.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.rememberNavController

object Routes {
    const val LOGIN = "login"
    const val REGISTER = "register"
    const val NOTES_LIST = "notes_list"
    const val NOTE_DETAIL = "note_detail/{noteId}"
    const val NOTE_EDIT = "note_edit/{noteId}"
    const val NOTE_CREATE = "note_create"

    fun noteDetail(noteId: String) = "note_detail/$noteId"
    fun noteEdit(noteId: String) = "note_edit/$noteId"
}

@Composable
fun NavGraph() {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = Routes.LOGIN
    ) {
        // Auth screens
        // composable(Routes.LOGIN) { }
        // composable(Routes.REGISTER) { }

        // Notes screens
        // composable(Routes.NOTES_LIST) { }
        // composable(Routes.NOTE_CREATE) { }
        // composable(Routes.NOTE_DETAIL) { }
        // composable(Routes.NOTE_EDIT) { }
    }
}
