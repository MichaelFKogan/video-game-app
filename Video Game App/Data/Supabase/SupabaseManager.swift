//
//  SupabaseManager.swift
//  Video Game App
//
//  Created by Mike K on 8/23/25.
//

import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://rpcbybhyxirakxtvlhhn.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwY2J5Ymh5eGlyYWt4dHZsaGhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1NDI3MjQsImV4cCI6MjA3MTExODcyNH0.ceu3sA4HS5hYhRBvTlbcRaMpUXS_eRxLpNG-JrCiHRc"
        )
    }
}
