import SwiftUI

struct LetterFlipView: View {
    let value: Int
    // NEU: Optionaler Countdown (Standard ist nil, damit es im Voting/Ergebnis nicht angezeigt wird)
    var remaining: Int? = nil
    var color: Color = .white
    
    var body: some View {
        ZStack {
            // Hintergrund-Box
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .frame(width: 100, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 5)
            
            // Der Buchstabe
            Text(value.asAlphabet)
                .font(.system(size: 70, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.interpolate)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
            
            // NEU: Der Badge oben rechts (nur wenn 'remaining' gesetzt ist)
            if let remaining = remaining, remaining > 0 {
                VStack {
                    HStack {
                        Spacer()
                        
                        Text("\(remaining)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.red) // Roter Badge für "Noch zu tun"
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1.5)
                            )
                            .shadow(radius: 2)
                            .offset(x: 8, y: -8) // Leicht über die Ecke hängen lassen
                    }
                    Spacer()
                }
                .frame(width: 100, height: 120) // Orientiert sich an der Kartengröße
            }
        }
    }
}
