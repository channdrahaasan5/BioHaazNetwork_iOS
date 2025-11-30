//
//  BioHaazSSLDelegate.swift
//  BioHaazNetwork
//
//  Handles SSL pinning for BioHaazNetwork
//

import Foundation
import CryptoKit
public class BioHaazSSLDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [String: String]?
    
    public init(pinnedCertificates: [String: String]?) {
        self.pinnedCertificates = pinnedCertificates
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String?,
              let pinnedHash = pinnedCertificates?[host] else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        // Evaluate server trust
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
//        var secresult = SecTrustResultType.invalid
        //        let status = SecTrustEvaluate(serverTrust, &secresult)
        //        if status == errSecSuccess {
        //            if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
        //                let serverCertData = SecCertificateCopyData(serverCert) as Data
        //                // SHA256 hash
        //                let hash = sha256(data: serverCertData)
        //                if hash == pinnedHash {
        //                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
        //                    return
        //                }
        //            }
        //        }
        //        // When pinning fails, provide a way to surface BioHaazNetworkError.sslPinningFailed(reason:) to the caller (e.g., via delegate or completion handler).
        //        completionHandler(.cancelAuthenticationChallenge, nil)
        
#if swift(>=5.1)
        if #available(iOS 13.0, *) {
            var error: CFError?
            let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
            if isTrusted {
                if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                    let serverCertData = SecCertificateCopyData(serverCert) as Data
                    // SHA256 hash
                    let hash = sha256(data: serverCertData)
                    if hash == pinnedHash {
                        completionHandler(.useCredential, URLCredential(trust: serverTrust))
                        return
                    }
                }
            }
            // When pinning fails, provide a way to surface BioHaazNetworkError.sslPinningFailed(reason:) to the caller (e.g., via delegate or completion handler).
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            var secresult = SecTrustResultType.invalid
            let status = SecTrustEvaluate(serverTrust, &secresult)
            if status == errSecSuccess {
                if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                    let serverCertData = SecCertificateCopyData(serverCert) as Data
                    // SHA256 hash
                    let hash = sha256(data: serverCertData)
                    if hash == pinnedHash {
                        completionHandler(.useCredential, URLCredential(trust: serverTrust))
                        return
                    }
                }
            }
            // When pinning fails, provide a way to surface BioHaazNetworkError.sslPinningFailed(reason:) to the caller (e.g., via delegate or completion handler).
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
#else
        var secresult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secresult)
        if status == errSecSuccess {
            if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                let serverCertData = SecCertificateCopyData(serverCert) as Data
                // SHA256 hash
                let hash = sha256(data: serverCertData)
                if hash == pinnedHash {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                }
            }
        }
        // When pinning fails, provide a way to surface BioHaazNetworkError.sslPinningFailed(reason:) to the caller (e.g., via delegate or completion handler).
        completionHandler(.cancelAuthenticationChallenge, nil)
#endif
    }
    
    private func sha256(data: Data) -> String {
#if canImport(CryptoKit)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
#else
        // Fallback for older iOS
        return data.base64EncodedString()
#endif
    }
}
