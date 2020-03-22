//
//  ViewController+ARSessionDeletegate.swift
//  ImageDetection
//
//  Created by GUNNER on 2020/2/20.
//  Copyright © 2020 GUNNER. All rights reserved.
//

import ARKit

extension ViewController: ARSessionDelegate {
    // MARK: ARSessionDelegate
    // 摄像头追踪状态发生变化回调
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        // 在状态视图区域展示追踪质量信息
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
            // 当摄像头追踪状态不可以用时，在状态视图区域给予反馈
        case .notAvailable, .limited:
            statusViewController.esacalteFeedback(for: camera.trackingState, inSeconds: 3.0)
            // 当摄像头追踪状态恢复正常时，取消状态视图区域的消息
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
        
    }
    
    // 会话异常回调
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Use `flatMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        // 异步展示异常信息
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        statusViewController.showMessage("""
        SESSION INTERRUPTED
        The session will be reset after the interruption has ended.
        """, autoHide: false)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        statusViewController.showMessage("RESETTING SESSION")
        
        restartExperience()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // 模糊背景
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        // 呈现一个关于发生的异常的告警提示
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Interface Action
    
    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        
        statusViewController.cancelAllScheduledMessage()
        
        resetTracking()
        
        // 为了让会话完成重启，禁止重启重启一段时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
}
