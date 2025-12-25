//
//  MessagesViewController.swift
//  ferdle MessagesExtension
//
//  UIKit host for SwiftUI content, handles iMessage integration and auto-expansion.
//

import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

    private var hostingController: UIHostingController<FerdleRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIHost()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Auto-expand to full height
        requestPresentationStyle(.expanded)
    }

    // MARK: - SwiftUI Hosting

    private func setupSwiftUIHost() {
        // Create the SwiftUI root view with share callback
        let rootView = FerdleRootView { [weak self] summary in
            self?.insertSummaryText(summary)
        }

        let hosting = UIHostingController(rootView: rootView)
        hostingController = hosting

        // Add as child view controller
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        // Setup constraints
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Share Functionality

    /// Inserts the Wordle summary text into the active conversation.
    private func insertSummaryText(_ summary: String) {
        guard let conversation = activeConversation else { return }

        conversation.insertText(summary) { error in
            if let error = error {
                print("Error inserting text: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Conversation Handling

    override func willBecomeActive(with conversation: MSConversation) {
        // Extension is becoming active - presentation style will be requested in viewDidAppear
    }

    override func didResignActive(with conversation: MSConversation) {
        // Extension is resigning - state is persisted automatically by GameViewModel
    }
}
