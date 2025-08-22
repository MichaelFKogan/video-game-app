import SwiftUI
import Supabase
import Auth

// Initialize Supabase client
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://rpcbybhyxirakxtvlhhn.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwY2J5Ymh5eGlyYWt4dHZsaGhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1NDI3MjQsImV4cCI6MjA3MTExODcyNH0.ceu3sA4HS5hYhRBvTlbcRaMpUXS_eRxLpNG-JrCiHRc"
)

struct Auth: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var message = ""
    
    @AppStorage("accentColorName") private var accentColorName: String = "blue"
    @State private var isLoading = false
    
    @EnvironmentObject var session: SessionStore
    @State private var messageColor: Color = .red
    
    var body: some View {
        VStack(spacing: 20) {
            // Current user
            if let user = session.user {
                Text("Logged in")
                    .foregroundColor(.green).opacity(0.8)
                Button("Log Out") {
                    Task { await session.signOut() } // no MainActor.run needed
                }
                .foregroundColor(.secondary)
            } else {
                Text("Not logged in")
            }
            
            Picker("", selection: $isLoginMode) {
                Text("Login").tag(true)
                Text("Sign Up").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                Task {
                    isLoginMode ? await login() : await signUp()
                }
            }) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(accentColorName.toColor())
                    .cornerRadius(8)
            }
            .frame(width: 200)

            if isLoading {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            }

            Text(message)
                .foregroundColor(messageColor)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onOpenURL { url in
            Task {
                do {
                    let session = try await supabase.auth.session(from: url)
                    self.session.user = session.user
                } catch {
                    print("Error handling callback: \(error.localizedDescription)")
                    message = "Error handling callback: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Supabase Auth Calls
    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Please enter both email and password."
            messageColor = .red
            return
        }
        do {
            // 1️⃣ Sign up with Supabase Auth
            let response = try await supabase.auth.signUp(email: email, password: password)
            let user = response.user // <- no optional binding
            
            // 2️⃣ Create empty profile in 'users' table
            try await supabase.database
                .from("profiles")
                .insert([
                    [
                        "id": user.id.uuidString,
                        "username": "",
                        "profile_photo_url": ""
                    ]
                ])
                .execute()
            
            // 3️⃣ Sign in immediately
            let loginResponse = try await supabase.auth.signIn(email: email, password: password)
            session.user = loginResponse.user
            
            message = "Signed up and logged in as \(loginResponse.user.email ?? "unknown")"
            messageColor = .green
            
        } catch {
            print("Sign Up Error: \(error.localizedDescription)")
            message = "Sign Up Error: \(error.localizedDescription)"
            messageColor = .red
        }
    }


    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            message = "Please enter both email and password."
            messageColor = .red
            return
        }
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            session.user = response.user
            message = "Success"
            messageColor = .green
        } catch {
            message = "Login Error: \(error.localizedDescription)"
            messageColor = .red
        }
    }
}
