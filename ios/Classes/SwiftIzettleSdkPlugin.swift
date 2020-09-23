import Flutter
import UIKit
import iZettleSDK.Swift

let keyWindow = UIApplication.shared.keyWindow?.rootViewController;

public class SwiftIzettleSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vhelp.co.uk/izettle_sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftIzettleSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "charge": return handleCharge(call: call, result: result);
        case "start": return handleStart(call: call, result: result);
        case "refund": return handleRefund(call: call, result: result);
        default:
            return result(FlutterError(code: "METHOD_NOT_IMPLEMENTED", message: "Method not found!", details: nil));
        }
    }

    public func handleStart(call: FlutterMethodCall, result: @escaping FlutterResult) {
        call.arguments.flatMap({ args in
            args as? Dictionary<String, Any>
        }).flatMap({ dict in
            do {
                let auth = try iZettleSDKAuthorization(
                        clientID: dict["clientID"].unsafelyUnwrapped as! String,
                        callbackURL: URL(string: dict["callbackURL"].unsafelyUnwrapped as! String)!,
                        enforcedUserAccount: dict["reinforcedUserAccount"].unsafelyUnwrapped as? String
                )

                iZettleSDK.shared().start(with: auth)
                result(true)
            } catch {
                result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
            }
        })
    }

    public func handleCharge(call: FlutterMethodCall, result: @escaping FlutterResult) {
        call.arguments.flatMap({ args in
            args as? Dictionary<String, Any>
        }).flatMap({ dict in
            
            let args = ChargeArguments(
                amount: NSDecimalNumber(decimal: (dict["amount"].unsafelyUnwrapped as! NSNumber).decimalValue),
                enableTipping: dict["enableTipping"].unsafelyUnwrapped as! Bool,
                reference: dict["reference"].unsafelyUnwrapped as? String
            )

            
            iZettleSDK.shared().charge(
                amount: args.amount,
                enableTipping: args.enableTipping,
                reference: args.reference,
                presentFrom: keyWindow!,
                    completion: { info, error in
                        error.flatMap({err in
                            result(FlutterError(code: "CHARGE_FAILED", message: err.localizedDescription, details: nil))
                        })

                        info.flatMap({r in
                            result(r.referenceNumber)
                        })
                    }
            )
        })
    }

    public func handleRefund(call: FlutterMethodCall, result: @escaping FlutterResult) {
        call.arguments.flatMap({ args in
            args as? Dictionary<String, Any>
        }).flatMap({ dict in
            let args = RefundArguments(
                amount: NSDecimalNumber(decimal: (dict["amount"].unsafelyUnwrapped as? NSNumber)?.decimalValue ?? -1),
                ofPayment: dict["ofPayment"].unsafelyUnwrapped as! String,
                refundReference: dict["refundReference"].unsafelyUnwrapped as? String
            )
                        
            iZettleSDK.shared().refund(
                    amount: args.amount,
                    ofPayment: args.ofPayment,
                    withRefundReference: args.refundReference,
                    presentFrom: keyWindow!,
                    completion: { info, error in
                        error.flatMap({err in
                            result(FlutterError(code: "REFUND_FAILED", message: err.localizedDescription, details: nil))
                        })

                        info.flatMap({r in
                            result(r.referenceNumber)
                        })
                    }
            )
        })
    }
}

struct ChargeArguments {
    var amount: NSDecimalNumber;
    var enableTipping: Bool;
    var reference: String?;
}

struct RefundArguments{
    var amount: NSDecimalNumber?;
    var ofPayment: String;
    var refundReference: String?;
}
