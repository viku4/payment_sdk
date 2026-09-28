package com.payment.payment_sdk

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PaymentSdkPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "PaymentSDK"
        private const val CHANNEL = "payment_sdk/upi"
    }

    private var applicationContext: Context? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(
        @NonNull binding: FlutterPlugin.FlutterPluginBinding
    ) {
        applicationContext = binding.applicationContext

        channel = MethodChannel(
            binding.binaryMessenger,
            CHANNEL
        )

        channel?.setMethodCallHandler(this)

        Log.d(
            TAG,
            "Payment SDK plugin attached"
        )
    }

    override fun onMethodCall(
        call: MethodCall,
        @NonNull result: MethodChannel.Result
    ) {
        Log.d(
            TAG,
            "Method: ${call.method}"
        )

        when (call.method) {

            "getInstalledUPIApps" -> {
                getInstalledUPIApps(result)
            }

            "launchUPI" -> {
                launchUPI(call, result)
            }

            "debugUPIApps" -> {
                debugUPIApps(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    // -------------------------------------------------------------------------
    // GET INSTALLED UPI APPS
    // -------------------------------------------------------------------------

    private fun getInstalledUPIApps(
        result: MethodChannel.Result
    ) {
        val context = applicationContext

        if (context == null) {
            result.error(
                "CONTEXT_ERROR",
                "Application context is not available",
                null
            )
            return
        }

        try {
            val packageManager =
                context.packageManager

            val uri = Uri.parse(
                "upi://pay" +
                    "?pa=test@upi" +
                    "&pn=Test" +
                    "&am=1.00" +
                    "&cu=INR"
            )

            val intent = Intent(
                Intent.ACTION_VIEW,
                uri
            ).apply {
                addCategory(
                    Intent.CATEGORY_DEFAULT
                )
            }

            val activities =
                packageManager.queryIntentActivities(
                    intent,
                    0
                )

            Log.d(
                TAG,
                "UPI handlers found: ${activities.size}"
            )

            val apps = activities
                .mapNotNull { resolveInfo ->

                    val packageName =
                        resolveInfo.activityInfo?.packageName
                            ?: return@mapNotNull null

                    val appName =
                        resolveInfo.loadLabel(
                            packageManager
                        )?.toString()
                            ?.takeIf {
                                it.isNotBlank()
                            }
                            ?: packageName

                    mapOf(
                        "appName" to appName,
                        "packageName" to packageName
                    )
                }
                .distinctBy {
                    it["packageName"]
                }
                .sortedBy {
                    it["appName"]
                        ?.toString()
                        ?.lowercase()
                }

            apps.forEach { app ->
                Log.d(
                    TAG,
                    "UPI APP: ${app["appName"]} | ${app["packageName"]}"
                )
            }

            result.success(apps)

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Failed to detect UPI applications",
                e
            )

            result.error(
                "UPI_DETECTION_ERROR",
                e.message
                    ?: "Unable to detect UPI applications",
                null
            )
        }
    }

    // -------------------------------------------------------------------------
    // LAUNCH SELECTED UPI APP
    // -------------------------------------------------------------------------

    private fun launchUPI(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val context = applicationContext

        if (context == null) {
            result.error(
                "CONTEXT_ERROR",
                "Application context is not available",
                null
            )
            return
        }

        val upiUri =
            call.argument<String>("upiUri")

        val packageName =
            call.argument<String>("packageName")

        if (upiUri.isNullOrBlank()) {
            result.error(
                "INVALID_URI",
                "UPI payment URI is empty",
                null
            )
            return
        }

        if (packageName.isNullOrBlank()) {
            result.error(
                "INVALID_PACKAGE",
                "UPI application package name is empty",
                null
            )
            return
        }

        try {

            Log.d(
                TAG,
                "Launching UPI"
            )

            Log.d(
                TAG,
                "Package: $packageName"
            )

            Log.d(
                TAG,
                "URI: $upiUri"
            )

            val uri = Uri.parse(upiUri)

            // IMPORTANT:
            // setPackage() guarantees that Android launches
            // the application selected by the user.
            val intent = Intent(
                Intent.ACTION_VIEW,
                uri
            ).apply {

                setPackage(packageName)

                addCategory(
                    Intent.CATEGORY_DEFAULT
                )

                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK
                )
            }

            val packageManager =
                context.packageManager

            val resolveInfo =
                packageManager.resolveActivity(
                    intent,
                    0
                )

            if (resolveInfo == null) {

                Log.e(
                    TAG,
                    "Selected UPI app cannot handle URI"
                )

                result.error(
                    "APP_NOT_FOUND",
                    "Selected UPI application cannot handle this payment",
                    null
                )

                return
            }

            Log.d(
                TAG,
                "Resolved package: ${resolveInfo.activityInfo?.packageName}"
            )

            context.startActivity(intent)

            Log.d(
                TAG,
                "UPI application launched successfully"
            )

            result.success(true)

        } catch (e: ActivityNotFoundException) {

            Log.e(
                TAG,
                "UPI application not found",
                e
            )

            result.error(
                "APP_NOT_FOUND",
                "Unable to open selected UPI application",
                null
            )

        } catch (e: Exception) {

            Log.e(
                TAG,
                "UPI launch failed",
                e
            )

            result.error(
                "UPI_LAUNCH_ERROR",
                e.message
                    ?: "Unable to open UPI application",
                null
            )
        }
    }

    // -------------------------------------------------------------------------
    // DEBUG
    // -------------------------------------------------------------------------

    private fun debugUPIApps(
        result: MethodChannel.Result
    ) {
        val context = applicationContext

        if (context == null) {
            result.error(
                "CONTEXT_ERROR",
                "Application context is not available",
                null
            )
            return
        }

        try {

            val packageManager =
                context.packageManager

            val uri = Uri.parse(
                "upi://pay"
            )

            val intent = Intent(
                Intent.ACTION_VIEW,
                uri
            )

            val activities =
                packageManager.queryIntentActivities(
                    intent,
                    0
                )

            Log.e(
                TAG,
                "================================"
            )

            Log.e(
                TAG,
                "******** UPI DEBUG ********"
            )

            Log.e(
                TAG,
                "Application: ${context.packageName}"
            )

            Log.e(
                TAG,
                "UPI handlers: ${activities.size}"
            )

            activities.forEach { info ->

                Log.e(
                    TAG,
                    "APP: ${info.loadLabel(packageManager)} | " +
                        "${info.activityInfo.packageName} | " +
                        "${info.activityInfo.name}"
                )
            }

            Log.e(
                TAG,
                "================================"
            )

            result.success(
                activities.map {
                    mapOf(
                        "appName" to it.loadLabel(
                            packageManager
                        ).toString(),
                        "packageName" to
                            it.activityInfo.packageName,
                        "activityName" to
                            it.activityInfo.name
                    )
                }
            )

        } catch (e: Exception) {

            Log.e(
                TAG,
                "UPI debug failed",
                e
            )

            result.error(
                "DEBUG_ERROR",
                e.message,
                null
            )
        }
    }

    // -------------------------------------------------------------------------
    // DETACH
    // -------------------------------------------------------------------------

    override fun onDetachedFromEngine(
        @NonNull binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel?.setMethodCallHandler(null)

        channel = null
        applicationContext = null

        Log.d(
            TAG,
            "Payment SDK plugin detached"
        )
    }
}