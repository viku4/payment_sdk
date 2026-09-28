package com.payment.payment_sdk

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PaymentSdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        this.flutterPluginBinding = flutterPluginBinding

        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "payment_sdk/upi"
        )

        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {

            "getInstalledUPIApps" -> {
                getInstalledUPIApps(result)
            }

            "launchUPI" -> {
                launchUPI(call, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    // ==========================================================
    // GET INSTALLED UPI APPS
    // ==========================================================

    private fun getInstalledUPIApps(
        result: MethodChannel.Result
    ) {
        try {
            val context = flutterPluginBinding.applicationContext
            val packageManager = context.packageManager

            val intent = Intent(Intent.ACTION_VIEW)
            intent.data = Uri.parse("upi://pay")

            val activities = packageManager.queryIntentActivities(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY
            )

            val apps = activities.mapNotNull { resolveInfo ->

                val packageName =
                    resolveInfo.activityInfo?.packageName
                        ?: return@mapNotNull null

                val appName =
                    resolveInfo.loadLabel(packageManager)
                        ?.toString()
                        ?: packageName

                mapOf(
                    "appName" to appName,
                    "packageName" to packageName
                )
            }

            result.success(apps)

        } catch (e: Exception) {

            result.error(
                "UPI_APPS_ERROR",
                e.message ?: "Unable to detect UPI applications",
                null
            )
        }
    }

    // ==========================================================
    // LAUNCH SELECTED UPI APP
    // ==========================================================

    private fun launchUPI(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        try {

            val upiUri = call.argument<String>("upiUri")
            val packageName = call.argument<String>("packageName")

            if (upiUri.isNullOrBlank()) {
                result.error(
                    "INVALID_UPI_URI",
                    "UPI URI is empty",
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

            val context =
                flutterPluginBinding.applicationContext

            val intent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse(upiUri)
            )

            intent.setPackage(packageName)

            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK
            )

            context.startActivity(intent)

            result.success(true)

        } catch (e: android.content.ActivityNotFoundException) {

            result.error(
                "ACTIVITY_NOT_FOUND",
                "Selected UPI application cannot handle this payment",
                null
            )

        } catch (e: Exception) {

            result.error(
                "UPI_LAUNCH_ERROR",
                e.message ?: "Unable to open UPI application",
                null
            )
        }
    }

    // ==========================================================
    // DETACH
    // ==========================================================

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)
    }
}