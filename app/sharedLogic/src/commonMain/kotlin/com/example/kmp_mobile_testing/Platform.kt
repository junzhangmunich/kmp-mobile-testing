package com.example.kmp_mobile_testing

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform