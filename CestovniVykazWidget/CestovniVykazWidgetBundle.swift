//
//  CestovniVykazWidgetBundle.swift
//  CestovniVykazWidget
//
//  Created by Jakub Sedláček on 16.09.2025.
//

import WidgetKit
import SwiftUI

@main
struct CestovniVykazWidgetBundle: WidgetBundle {
    var body: some Widget {
        CestovniVykazWidget()
        CestovniVykazWidgetControl()
        CestovniVykazWidgetLiveActivity()
    }
}
