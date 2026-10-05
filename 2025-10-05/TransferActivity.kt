package com.pnc.jetpackcomposedemos

//
// TransferActivity_Starter.kt
// Module 13 — Android Architecture Patterns
// Lab Exercise: Refactor TransferActivity
//
// SCENARIO
// The Activity below is a Massive Activity: it mixes networking, validation,
// and UI update logic in one class. Your task is to refactor it using the
// patterns from this module.
//
// REQUIREMENTS
// 1. Extract a TransferViewModel with ZERO Android framework imports beyond
//    androidx.lifecycle.
// 2. Extract a TransferFundsUseCase encapsulating the eligibility check and
//    the transfer call.
// 3. Inject the Repository and UseCase via Hilt (@Inject constructor,
//    @HiltViewModel) — no manual construction, no singletons.
// 4. The refactored ViewModel must be unit-testable using a fake repository,
//    with no real network or Hilt container required.
//
// Read through BeforeMassiveTransferActivity below first — really read it,
// don't skim. Naming what's wrong with it is part of the exercise. Then
// fill in the TODOs in the scaffolding beneath it.
//

import android.app.Activity
import android.widget.Toast
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch

// MARK: - BEFORE: the Massive Activity (do not edit — refactor FROM this)

class BeforeMassiveTransferActivity : Activity() {
    lateinit var fromAccount: Account
    lateinit var toAccount: Account

    fun onTransferButtonClicked(amountText: String) {
        val amount = amountText.toDoubleOrNull()
        if (amount == null || amount <= 0) {
            Toast.makeText(this, "Please enter a valid amount", Toast.LENGTH_SHORT).show()
            return
        }
        if (fromAccount.balance < amount) {
            Toast.makeText(this, "Insufficient funds", Toast.LENGTH_SHORT).show()
            return
        }

        // Imagine a raw HTTP call inline here:
        // httpClient.post("/transfer", body = ...)
        // followed by manually updating a TextView, dismissing a dialog,
        // and navigating back — all mixed into this one function.
    }
}

// MARK: - Model (complete — no changes needed)

data class Account(
    val id: String,
    val name: String,
    val maskedNumber: String,
    val balance: Double
)

// MARK: - TODO 1: AccountsRepository interface

interface AccountsRepository {
    // TODO: declare a suspend function to perform a transfer between two
    // accounts for a given amount. Think about what parameters and return
    // type make sense given how it will be called from the UseCase.
    suspend fun transfer(
        fromAccountId: String,
        toAccountId: String,
        amount: Double
    ): Result<Unit>
}

// MARK: - TODO 2: TransferEligibilityService and TransferFundsUseCase

class TransferEligibilityService @Inject constructor() {
    fun canTransfer(amount: Double, from: Account): Boolean {
        return amount > 0 && from.balance >= amount
    }
}

class TransferFundsUseCase @Inject constructor(
    private val repository: AccountsRepository,
    private val eligibility: TransferEligibilityService
) {
    // TODO: inject AccountsRepository and TransferEligibilityService via
    // an @Inject constructor. Implement operator fun invoke(amount, from, to)
    // as a suspend function returning Result<Unit> — check eligibility
    // first, then call the repository if eligible.
    suspend operator fun invoke(amount: Double, from: Account, to: Account): Result<Unit> {
        if (!eligibility.canTransfer(amount, from)) {
            return Result.failure(IllegalArgumentException("Transfer not allowed"))
        }
        return repository.transfer(from.id, to.id, amount)
    }
}

// MARK: - TODO 3: TransferViewModel

sealed class TransferUiState {
    object Idle : TransferUiState()
    object Success : TransferUiState()
    data class Error(val message: String) : TransferUiState()
}

@HiltViewModel
class TransferViewModel @Inject constructor (
    private val transferFunds: TransferFundsUseCase
) : ViewModel() {
    // TODO: no Android framework import anywhere in this file below this
    // point, other than androidx.lifecycle. Annotate the class with
    // @HiltViewModel and inject TransferFundsUseCase via an @Inject
    // constructor. Expose a StateFlow<TransferUiState>. Implement
    // attemptTransfer(amount, from, to) that launches a coroutine in
    // viewModelScope, calls the use case, and updates the state.
    private val _uiState = MutableStateFlow<TransferUiState>(TransferUiState.Idle)
    val uiState: StateFlow<TransferUiState> = _uiState

    fun attemptTransfer(amount: Double, from: Account, to: Account) {
        viewModelScope.launch {
            _uiState.value = transferFunds(amount, from, to).fold(
                onSuccess = { TransferUiState.Success },
                onFailure = { TransferUiState.Error(it.message ?: "Transfer failed") }
            )
        }
    }
}
