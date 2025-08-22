//
//  SessionStore.swift
//  Video Game App
//
//  Created by Mike K on 8/18/25.
//

import Foundation
import Supabase

@MainActor
class SessionStore: ObservableObject {
    @Published var user: User? = nil
    var isLoggedIn: Bool { user != nil }

    init() {
        loadSession()
        Task { await subscribeToAuthChanges() } // call async function safely
    }

    private func loadSession() {
        self.user = supabase.auth.currentSession?.user
    }

    private func subscribeToAuthChanges() async {
        await supabase.auth.onAuthStateChange { [weak self] _, session in
            guard let self = self else { return }
            // Dispatch to main actor from synchronous closure
            Task { @MainActor in
                self.user = session?.user
            }
        }
    }


    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.user = nil
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
}
