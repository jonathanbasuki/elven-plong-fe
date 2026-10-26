import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: LoginViewModel
    @State private var isPasswordVisible: Bool = false
    
    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 300)
                
                // Bottom Login Card
                VStack(spacing: 0) {
                    Text("Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.top, 36)
                        .padding(.bottom, 28)
                    
                    // Unified Input Fields Card
                    VStack(spacing: 0) {
                        // Email Row
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                            }
                            
                            TextField("abcde@gmail.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .opacity(0.5)
                        
                        // Password Row
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                            }
                            
                            if isPasswordVisible {
                                TextField("*********", text: $viewModel.password)
                                    .font(.system(size: 16))
                            } else {
                                SecureField("*********", text: $viewModel.password)
                                    .font(.system(size: 16))
                            }
                            
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(uiColor: .systemGray2))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 24)
                    
                    // Validation Error Banner (if any)
                    if let error = viewModel.emailError ?? viewModel.passwordError ?? viewModel.generalError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                    }
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button {
                            // Forgot password action
                        } label: {
                            Text("Forgot Password ?")
                                .font(.system(size: 13, weight: .regular))
                                .underline()
                                .foregroundStyle(Color(uiColor: .systemGray))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    
                    Spacer(minLength: 44)
                    
                    // Blue Capsule Login Button
                    Button {
                        viewModel.signIn()
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 0.0, green: 0.46, blue: 0.92))
                        .clipShape(Capsule())
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(
                    Color(uiColor: .systemBackground)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 10, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(router: NavigationRouter()))
}
