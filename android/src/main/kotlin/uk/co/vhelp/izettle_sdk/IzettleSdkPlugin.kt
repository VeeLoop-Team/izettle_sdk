package uk.co.vhelp.izettle_sdk

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull;
import androidx.lifecycle.*
import com.izettle.android.commons.state.StateObserver
import com.izettle.payments.android.payment.TransactionReference
import com.izettle.payments.android.sdk.IZettleSDK
import com.izettle.payments.android.sdk.User
import com.izettle.payments.android.ui.SdkLifecycle
import com.izettle.payments.android.ui.payment.CardPaymentActivity
import com.izettle.payments.android.ui.payment.CardPaymentResult

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

/** IzettleSdkPlugin */
public class IzettleSdkPlugin : ActivityAware, FlutterPlugin, MethodCallHandler {
    private lateinit var activityWrapper: AsyncActivity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var loggedIn = false

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "vhelp.co.uk/izettle_sdk")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }


    private val authObserver = object : StateObserver<User.AuthState> {
        override fun onNext(state: User.AuthState) {
            when (state) {
                is User.AuthState.LoggedIn -> loggedIn = true
                is User.AuthState.LoggedOut -> loggedIn = false
            }
        }
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val channel = MethodChannel(registrar.messenger(), "vhelp.co.uk/izettle_sdk")
            val handler = IzettleSdkPlugin()
            channel.setMethodCallHandler(handler)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "start" -> handleStart(call, result)
            "charge" -> handleCharge(call, result)
            "refund" -> handleRefund(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun handleStart(@NonNull call: MethodCall, @NonNull result: Result) {
        IZettleSDK.init(
                context,
                call.argument<String>("clientID")!!,
                call.argument<String>("callbackURL")!!
        )

        ProcessLifecycleOwner.get().lifecycle.addObserver(SdkLifecycle(IZettleSDK))
        IZettleSDK.user.state
    }

    fun handleCharge(@NonNull call: MethodCall, @NonNull result: Result) {
        val reference = TransactionReference
                .Builder(call.argument<String>("reference").orEmpty())
                .build()

        val intent = CardPaymentActivity.IntentBuilder(context)
                .amount(call.argument<Long>("amount")!!)
                .enableLogin(!loggedIn)
                .enableTipping(call.argument<Boolean>("enableTipping")!!)
                .reference(reference)
                .build()


        GlobalScope.launch {
            val value = activityWrapper.launchIntent(intent).await()

            Handler(Looper.getMainLooper()).post {
                when (val payload = value?.data?.extras?.get(CardPaymentActivity.RESULT_EXTRA_PAYLOAD) as CardPaymentResult) {
                    is CardPaymentResult.Completed -> result.success(payload.toString())
                    is CardPaymentResult.Canceled -> result.error("PAYMENT_FAILED", payload.toString(), null)
                    is CardPaymentResult.Failed -> result.error("PAYMENT_FAILED", payload.toString(), null)
                }
            }
        }

        console("CHARGED")
    }

    fun handleRefund(@NonNull call: MethodCall, @NonNull result: Result) {

    }

    private fun doLogin() {
        IZettleSDK.user.login(activityWrapper.activity);
    }

    fun console(any: Any?) {
        print(any)
        Log.v("PLUGIN", any.toString() + "EEEEE")
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent): Boolean {
        console("result!!")
        console(data.extras?.get(CardPaymentActivity.RESULT_EXTRA_PAYLOAD))
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityWrapper = AsyncActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }
}

class ActivityResult(
        val resultCode: Int,
        val data: Intent?
)

class AsyncActivity(val binding: ActivityPluginBinding) {

    val activity = binding.activity

    var currentCode: Int = 0
    private var resultByCode = mutableMapOf<Int, CompletableDeferred<ActivityResult?>>()

    private var listenerRegistered = false

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        resultByCode[requestCode]?.let {
            it.complete(ActivityResult(resultCode, data))
            resultByCode.remove(requestCode)

            if (resultByCode.isEmpty()) {
                binding.removeActivityResultListener(this::onActivityResult)
                listenerRegistered = false
            }
        } ?: run {
//            this.onActivityResult(requestCode, resultCode, data)
        }
        return true
    }

    /**
     * Launches the intent allowing to process the result using await()
     *
     * @param intent the intent to be launched.
     *
     * @return Deferred<ActivityResult>
     */
    fun launchIntent(intent: Intent): Deferred<ActivityResult?> {
        val activityResult = CompletableDeferred<ActivityResult?>()

        if (!listenerRegistered) {
            binding.addActivityResultListener(this::onActivityResult)
            listenerRegistered = true
        }

        if (intent.resolveActivity(activity.packageManager) != null) {
            val resultCode = currentCode++
            resultByCode[resultCode] = activityResult
            activity.startActivityForResult(intent, resultCode)
        } else {
            activityResult.complete(null)
        }
        return activityResult
    }
}

//data class ChargeArguments()

//data class RefundArguments;