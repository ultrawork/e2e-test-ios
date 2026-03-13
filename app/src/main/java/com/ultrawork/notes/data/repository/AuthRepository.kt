package com.ultrawork.notes.data.repository

import com.ultrawork.notes.data.local.TokenManager
import com.ultrawork.notes.data.remote.ApiService
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val apiService: ApiService,
    private val tokenManager: TokenManager
) {
    // TODO: Implement auth operations (login, register, logout, delete account)
}
