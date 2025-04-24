import SwiftUI

struct PopoverView: View {
    @StateObject private var hydrationManager = HydrationManager()
    @State private var showSettings = false
    @State private var intakeAmount: Double = 250
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isAddingWater: Bool = false // Track when water is being added
    
    // Define constant colors for consistency
    private let accentColor = Color(red: 0.29, green: 0.48, blue: 0.97)  // Blue accent similar to reference image
    private let backgroundColor = Color(red: 0.12, green: 0.12, blue: 0.14)  // Dark background
    private let secondaryColor = Color(red: 0.22, green: 0.22, blue: 0.25)  // Slightly lighter dark
    private let textColor = Color.white
    private let secondaryTextColor = Color.gray
    
    var body: some View {
        ZStack {
            // Main background
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                Text("Hydrate")
                    .font(.headline)
                    .foregroundColor(textColor)
                    .padding(.top, 10)
                
                // Progress bar
                ProgressBarView(progress: hydrationManager.progressPercentage, color: accentColor)
                    .frame(height: 20)
                    .padding(.horizontal)
                
                // Current progress text
                Text("\(Int(hydrationManager.dailyGoal - hydrationManager.remainingTarget)) / \(Int(hydrationManager.dailyGoal)) ml consumed")
                    .font(.subheadline)
                    .foregroundColor(textColor)
                
                // Remaining target text
                Text("Remaining target: \(Int(hydrationManager.remainingTarget)) ml")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                
                Divider()
                    .background(secondaryTextColor)
                
                // Quick drink section
                VStack(spacing: 10) {
                    Text("Drink Water")
                        .font(.subheadline)
                        .foregroundColor(textColor)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            addWater(amount: 100)
                        }) {
                            Text("100ml")
                                .foregroundColor(isAddingWater ? .gray : .white)
                        }
                        .buttonStyle(ConsistentButtonStyle(color: accentColor))
                        .disabled(isAddingWater)
                        
                        Button(action: {
                            addWater(amount: 250)
                        }) {
                            Text("250ml")
                                .foregroundColor(isAddingWater ? .gray : .white)
                        }
                        .buttonStyle(ConsistentButtonStyle(color: accentColor))
                        .disabled(isAddingWater)
                        
                        Button(action: {
                            addWater(amount: 500)
                        }) {
                            Text("500ml")
                                .foregroundColor(isAddingWater ? .gray : .white)
                        }
                        .buttonStyle(ConsistentButtonStyle(color: accentColor))
                        .disabled(isAddingWater)
                    }
                    
                    // Custom amount
                    HStack {
                        Slider(value: $intakeAmount, in: 50...1000, step: 50)
                            .accentColor(accentColor)
                            .frame(width: 150)
                        
                        Button(action: {
                            addWater(amount: intakeAmount)
                        }) {
                            HStack(spacing: 0) {
                                Text("\(Int(intakeAmount))")
                                    .foregroundColor(isAddingWater ? .gray : .white)
                                    .frame(width: 40, alignment: .trailing)
                                
                                Text(" ml")
                                    .foregroundColor(isAddingWater ? .gray : .white)
                                    .frame(width: 25, alignment: .leading)
                            }
                        }
                        .buttonStyle(ConsistentButtonStyle(color: accentColor))
                        .disabled(isAddingWater)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .background(secondaryTextColor)
                
                // Reminder timer info with more accurate countdown
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(accentColor)
                    Text("Next reminder in: ")
                        .foregroundColor(secondaryTextColor)
                    Text(hydrationManager.formattedTimeRemaining())
                        .bold()
                        .foregroundColor(textColor)
                        .onReceive(timer) { _ in
                            // This will update the timer text every second
                        }
                }
                .font(.caption)
                
                Spacer()
                
                // Bottom buttons
                HStack {
                    Button(action: {
                        hydrationManager.resetTarget()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                    }
                    .buttonStyle(ConsistentButtonStyle(color: accentColor, isOutlined: true))
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                    }
                    .buttonStyle(ConsistentButtonStyle(color: accentColor))
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding()
            .background(secondaryColor)
            .cornerRadius(12)
            .frame(width: 300, height: 400)
            
            // Celebration overlay when goal is reached
            if hydrationManager.showCelebration {
                // Semi-transparent background
                Rectangle()
                    .fill(backgroundColor.opacity(0.9))
                    .edgesIgnoringSafeArea(.all)
                
                // Fireworks animation
                FireworksView(accentColor: accentColor)
                    .edgesIgnoringSafeArea(.all)
                
                // Celebration message
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("GOAL ACHIEVED! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accentColor.opacity(0.3))
                                .shadow(color: accentColor.opacity(0.5), radius: 5)
                        )
                    
                    Text("You've reached your daily goal of \(Int(hydrationManager.dailyGoal))ml!")
                        .font(.headline)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Continue") {
                        hydrationManager.showCelebration = false
                    }
                    .buttonStyle(ConsistentButtonStyle(color: accentColor))
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: hydrationManager.showCelebration)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(hydrationManager: hydrationManager)
        }
    }
    
    // Fungsi untuk menambahkan air dengan feedback haptic dan animasi
    private func addWater(amount: Double) {
        // Mencegah multiple tap cepat yang bisa menyebabkan error
        guard !isAddingWater && amount > 0 else { return }
        
        // Tanda sedang proses menambahkan air
        isAddingWater = true
        
        // Efek visual untuk feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            // Kurangi target yang tersisa
            hydrationManager.drinkWater(amount: amount)
        }
        
        // Delay sebentar untuk mencegah multiple tap yang tidak disengaja
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAddingWater = false
        }
    }
}

// Fireworks celebration view with updated style
struct FireworksView: View {
    let accentColor: Color
    @State private var fireworks: [Firework] = []
    @State private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    let fireworkColors: [Color] = [
        Color(red: 0.29, green: 0.48, blue: 0.97),  // Primary blue
        Color(red: 0.35, green: 0.55, blue: 1.0),   // Lighter blue
        Color(red: 0.4, green: 0.6, blue: 0.9),     // Another blue shade
        Color(red: 0.8, green: 0.8, blue: 1.0),     // Very light blue
        Color.white
    ]
    
    var body: some View {
        ZStack {
            // Transparent background (we're using the parent's background)
            Color.clear
                .edgesIgnoringSafeArea(.all)
            
            // Fireworks
            ForEach(fireworks) { firework in
                FireworkView(firework: firework)
            }
        }
        .onAppear {
            // Add initial fireworks
            for _ in 0..<5 {
                addFirework()
            }
        }
        .onReceive(timer) { _ in
            // Add more fireworks every 0.5 seconds
            if fireworks.count < 15 {
                addFirework()
            }
            
            // Remove old fireworks
            fireworks = fireworks.filter { $0.creationTime.timeIntervalSinceNow > -2.0 }
        }
    }
    
    func addFirework() {
        let newFirework = Firework(
            position: CGPoint(
                x: CGFloat.random(in: 50...250),
                y: CGFloat.random(in: 50...350)
            ),
            color: fireworkColors.randomElement() ?? accentColor,
            creationTime: Date()
        )
        fireworks.append(newFirework)
    }
}

// Individual firework
struct FireworkView: View {
    let firework: Firework
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(firework.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            // Create the particles for this firework
            createParticles()
        }
    }
    
    func createParticles() {
        for _ in 0..<50 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = Double.random(in: 20...100)
            let distance = Double.random(in: 20...80)
            let size = Double.random(in: 2...6)
            let duration = Double.random(in: 0.5...1.5)
            
            let endPosition = CGPoint(
                x: firework.position.x + cos(angle) * distance,
                y: firework.position.y + sin(angle) * distance
            )
            
            let particle = Particle(
                position: firework.position,
                endPosition: endPosition,
                size: size,
                speed: speed,
                opacity: 1.0,
                creationTime: Date()
            )
            
            particles.append(particle)
            
            // Animate the particle
            withAnimation(.easeOut(duration: duration)) {
                particles[particles.count - 1].position = endPosition
                particles[particles.count - 1].opacity = 0
            }
        }
    }
}

// Firework model
struct Firework: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let creationTime: Date
}

// Particle model
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let endPosition: CGPoint
    let size: Double
    let speed: Double
    var opacity: Double
    let creationTime: Date
}

// Consistent button style that can be configured for different uses
struct ConsistentButtonStyle: ButtonStyle {
    let color: Color
    var isOutlined: Bool = false
    var isSmall: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, isSmall ? 4 : 6)
            .padding(.horizontal, isSmall ? 8 : 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOutlined ? Color.clear : color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOutlined ? color : Color.clear, lineWidth: isOutlined ? 1.5 : 0)
                    )
            )
            .foregroundColor(isOutlined ? color : .white)
            .font(isSmall ? .caption : .body)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// Progress bar view with customizable color
struct ProgressBarView: View {
    var progress: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color.gray.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(color)
                    .animation(.easeInOut, value: progress)
            }
        }
    }
}

// Visual effect wrapper for consistency
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow // Using semantic material instead of deprecated 'dark'
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
} 