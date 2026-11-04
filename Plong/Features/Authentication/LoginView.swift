import SwiftUI

/// Login View matching sample/Manager/login.svg conforming to Apple HIG.
public struct LoginView: View {
    @Bindable var viewModel: LoginViewModel
    @State private var isPasswordVisible: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Centered "Login" Title
                Text("Login")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .padding(.bottom, 36)
                    .accessibilityAddTraits(.isHeader)
                
                // Grouped Inputs Card
                VStack(spacing: 0) {
                    // Email Row
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 38, height: 38)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)
                        
                        TextField("abcde@gmail.com", text: $viewModel.email)
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .font(.system(size: 16))
                            .foregroundStyle(Color(uiColor: .label))
                            .accessibilityLabel("Email Address")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    
                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.5)
                    
                    // Password Row
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 38, height: 38)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)
                        
                        if isPasswordVisible {
                            TextField("*********", text: $viewModel.password)
                                .focused($focusedField, equals: .password)
                                .font(.system(size: 16))
                                .foregroundStyle(Color(uiColor: .label))
                                .accessibilityLabel("Password")
                        } else {
                            SecureField("*********", text: $viewModel.password)
                                .focused($focusedField, equals: .password)
                                .font(.system(size: 16))
                                .foregroundStyle(Color(uiColor: .label))
                                .accessibilityLabel("Password")
                        }
                        
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(uiColor: .systemGray2))
                                .frame(width: 44, height: 44) // HIG hit target
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .background(Color(uiColor: .systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 24)
                
                // Error feedback if any
                if let error = viewModel.emailError ?? viewModel.passwordError ?? viewModel.generalError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundStyle(Color(uiColor: .systemRed))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // Bottom Primary Login Button
                PrimaryPillButton(
                    title: "Login",
                    isEnabled: !viewModel.isLoading,
                    isLoading: viewModel.isLoading
                ) {
                    dismissKeyboard()
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.signIn()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        // Dismiss keyboard on tap outside input fields
        .onTapGesture {
            dismissKeyboard()
        }
    }
    
    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(router: NavigationRouter()))
}
