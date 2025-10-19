import SwiftUI
import Combine

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    @State private var progress: CGFloat = 0.0
    @State private var showApp = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Centered content
                VStack(spacing: 40) {
                // App Logo and Title
                VStack(spacing: 20) {
                    // Animated Logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: isAnimating)
                    }
                    
                    // App Title
                    VStack(spacing: 8) {
                        Text("Cestovní výkaz")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Pro mechaniky")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                // Progress Bar
                VStack(spacing: 16) {
                    // Progress Bar Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                        .overlay(
                            // Progress Bar Fill
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: progress * 250, height: 8)
                                    .animation(.easeInOut(duration: 0.5), value: progress)
                                
                                Spacer()
                            }
                        )
                        .frame(width: 250)
                    
                    // Loading Text
                    Text("Načítání aplikace...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                }
                
                Spacer()
                
                // Creator info - positioned at bottom
                VStack(spacing: -10) {
                    Text("Vytvořeno společností")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Image("klimexlogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 60)
                        .opacity(0.9)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startLoading()
        }
    }
    
    private func startLoading() {
        // Start animations
        isAnimating = true
        
        // Simulate loading progress - smooth forward progression only
        withAnimation(.easeInOut(duration: 0.3)) {
            progress = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                progress = 0.7
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                progress = 1.0
            }
        }
        
        // Show main app after loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showApp = true
            }
        }
    }
}

// MARK: - Loading Screen Manager
class LoadingScreenManager: ObservableObject {
    @Published var isLoading = true
    
    static let shared = LoadingScreenManager()
    
    private init() {}
    
    func finishLoading() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }
}

// MARK: - Main App Wrapper
struct AppWrapper: View {
    @StateObject private var loadingManager = LoadingScreenManager.shared
    
    var body: some View {
                            ZStack {
                        if loadingManager.isLoading {
                            LoadingView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        } else {
                            MechanicTabView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
        .onAppear {
            // Simulate minimum loading time
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                loadingManager.finishLoading()
            }
        }
    }
}

#Preview {
    LoadingView()
} 
