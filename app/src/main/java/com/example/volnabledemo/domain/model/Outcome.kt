package com.example.volnabledemo.domain.model

import com.example.volnabledemo.domain.error.Failure

sealed interface Outcome<out T, out F : Failure> {
    data class Success<T>(val value: T) : Outcome<T, Nothing>
    data class FailureResult<F : Failure>(val reason: F) : Outcome<Nothing, F>
}

inline fun <T, F : Failure> Outcome<T, F>.onSuccess(block: (T) -> Unit): Outcome<T, F> {
    if (this is Outcome.Success) block(value)
    return this
}

inline fun <T, F : Failure> Outcome<T, F>.onFailure(block: (F) -> Unit): Outcome<T, F> {
    if (this is Outcome.FailureResult) block(reason)
    return this
}

inline fun <T, F : Failure, R> Outcome<T, F>.fold(
    onSuccess: (T) -> R,
    onFailure: (F) -> R,
): R = when (this) {
    is Outcome.Success -> onSuccess(value)
    is Outcome.FailureResult -> onFailure(reason)
}
