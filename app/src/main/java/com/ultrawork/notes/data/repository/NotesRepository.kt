package com.ultrawork.notes.data.repository

import com.ultrawork.notes.data.remote.ApiService
import javax.inject.Inject
import javax.inject.Singleton

@Suppress("UnusedPrivateProperty")
@Singleton
class NotesRepository @Inject constructor(
    private val apiService: ApiService
) {
    // TODO: Implement notes CRUD operations
}
