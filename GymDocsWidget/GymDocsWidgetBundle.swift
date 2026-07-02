//
//  GymDocsWidgetBundle.swift
//  GymDocsWidget
//
//  Created by 김동진 on 7/2/26.
//

import WidgetKit
import SwiftUI

@main
struct GymDocsWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymDocsWidget()
        GymDocsWidgetControl()
        GymDocsWidgetLiveActivity()
        RestTimerWidget()
    }
}
