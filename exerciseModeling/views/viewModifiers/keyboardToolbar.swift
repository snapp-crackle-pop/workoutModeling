//
//  keyboardToolbar.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/6/24.
//

import SwiftUI

struct KeyboardToolbar: ViewModifier {
    let moveNext: () -> Void
    let dismiss: () -> Void
    let showNext: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Close") {
                        dismiss()
                    }
                    Spacer()
                    Button(showNext ? "Next" : "Done") {
                        moveNext()
                    }
                }
            }
    }
}
