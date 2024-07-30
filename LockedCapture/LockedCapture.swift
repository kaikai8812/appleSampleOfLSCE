//
//  LockedCapture.swift
//  LockedCapture
//
//  Created by aoyamakai on 2024/07/30.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import LockedCameraCapture
import SwiftUI

@main
struct LockedCapture: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            LockedCaptureViewFinder(session: session)
        }
    }
}
