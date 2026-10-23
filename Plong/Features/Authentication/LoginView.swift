import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: LoginViewModel
    
    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("CrowdFlow")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                    
                    Text("Venue Crowd Monitoring & Deployment MVP")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Address")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                        
                        TextField("manager@venue.com", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color(white: 0.95))
                            .overlay(
                                Rectangle()
                                    .stroke(viewModel.emailError != nil ? Color.red : Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        
                        if let error = viewModel.emailError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                        
                        SecureField("••••••••", text: $viewModel.password)
                            .padding(12)
                            .background(Color(white: 0.95))
                            .overlay(
                                Rectangle()
                                    .stroke(viewModel.passwordError != nil ? Color.red : Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        
                        if let error = viewModel.passwordError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    if let generalError = viewModel.generalError {
                        Text(generalError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    // Sign In Button
                    Button {
                        viewModel.signIn()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.black)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.top, 8)
                    
                    // Quick Demo Fill
                    Button {
                        viewModel.email = "manager@crowdflow.internal"
                        viewModel.password = "security2026"
                    } label: {
                        Text("Quick Demo Credentials")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(Color(white: 0.98))
                .border(Color.gray.opacity(0.3), width: 1)
                
                Spacer()
                
                Text("Low-Fidelity Functional Prototype")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 24)
        }
    }
}
