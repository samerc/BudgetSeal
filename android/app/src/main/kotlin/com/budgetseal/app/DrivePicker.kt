package com.budgetseal.app

import android.accounts.Account
import android.app.Activity
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.FragmentActivity
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.AuthorizationRequest.ResourceParameter
import com.google.android.gms.auth.api.identity.AuthorizationResult
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.Scope
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// Google's Drive picker, shown by Google during authorization
/// (`PICKER_OAUTH_TRIGGER`). The app keeps the narrow drive.file scope: what
/// the user picks is what it may open — a folder another account shared, or
/// one the user wants the budget in.
///
/// Channel `budgetseal/drive_picker`, method `pick`:
///   email      — the account to use (null: Google asks which one)
///   fileIds    — ids to show selected (an invite's folder)
///   folders    — let folders be picked
///   picker     — false: only authorize (no picker), for tests
/// returns {token, picked: [ids]} or null when the user backed out.
class DrivePicker(private val activity: FragmentActivity) {
    private var pending: MethodChannel.Result? = null

    // Registered before the activity starts (FragmentActivity requires it).
    private val launcher: ActivityResultLauncher<IntentSenderRequest> =
        activity.registerForActivityResult(
            ActivityResultContracts.StartIntentSenderForResult()
        ) { res ->
            val result = pending ?: return@registerForActivityResult
            pending = null
            if (res.resultCode != Activity.RESULT_OK || res.data == null) {
                result.success(null)
                return@registerForActivityResult
            }
            try {
                val auth = Identity.getAuthorizationClient(activity)
                    .getAuthorizationResultFromIntent(res.data)
                result.success(toMap(auth))
            } catch (e: Exception) {
                Log.w(TAG, "picker result failed: $e")
                result.error("failed", e.message, null)
            }
        }

    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "budgetseal/drive_picker").setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> pick(
                    email = call.argument<String>("email"),
                    fileIds = call.argument<List<String>>("fileIds") ?: emptyList(),
                    folders = call.argument<Boolean>("folders") ?: false,
                    picker = call.argument<Boolean>("picker") ?: true,
                    result = result,
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun pick(
        email: String?,
        fileIds: List<String>,
        folders: Boolean,
        picker: Boolean,
        result: MethodChannel.Result,
    ) {
        if (pending != null) {
            result.error("busy", "A picker is already open", null)
            return
        }
        val builder = AuthorizationRequest.builder()
            .setRequestedScopes(listOf(Scope(DRIVE_FILE)))
        if (email != null) builder.setAccount(Account(email, "com.google"))
        if (picker) {
            builder
                // Only drive.file may come back with the picker.
                .setOptOutIncludingGrantedScopes(true)
                .setPrompt(
                    if (email == null)
                        AuthorizationRequest.Prompt.CONSENT or AuthorizationRequest.Prompt.SELECT_ACCOUNT
                    else AuthorizationRequest.Prompt.CONSENT
                )
                .addResourceParameter(ResourceParameter.PICKER_OAUTH_TRIGGER, "true")
            if (folders) builder.addResourceParameter(ResourceParameter.PICKER_ALLOW_FOLDER_SELECTION, "true")
            if (fileIds.isNotEmpty()) {
                builder.addResourceParameter(ResourceParameter.PICKER_FILE_IDS, fileIds.joinToString(","))
            }
        } else if (email == null) {
            builder.setPrompt(AuthorizationRequest.Prompt.SELECT_ACCOUNT)
        }
        Identity.getAuthorizationClient(activity).authorize(builder.build())
            .addOnSuccessListener { auth ->
                if (auth.hasResolution()) {
                    val intent = auth.pendingIntent
                    if (intent == null) {
                        result.error("failed", "No picker to show", null)
                        return@addOnSuccessListener
                    }
                    pending = result
                    launcher.launch(IntentSenderRequest.Builder(intent.intentSender).build())
                } else {
                    result.success(toMap(auth))
                }
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "authorize failed: $e")
                result.error("failed", e.message, null)
            }
    }

    private fun toMap(auth: AuthorizationResult): Map<String, Any?> {
        val picked = auth.tokenResponseParams?.getString("picked_file_ids")
            ?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
        return mapOf("token" to auth.accessToken, "picked" to picked)
    }

    companion object {
        private const val TAG = "BudgetSealPicker"
        private const val DRIVE_FILE = "https://www.googleapis.com/auth/drive.file"
    }
}
