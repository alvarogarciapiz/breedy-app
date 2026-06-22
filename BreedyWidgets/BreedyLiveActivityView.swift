import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Configuration

struct BreedyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreedySessionAttributes.self) { context in
            // MARK: Lock Screen / Banner View
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    phaseIconView(context: context)
                        .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    cycleCountView(context: context)
                        .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    expandedCenterView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomView(context: context)
                }
            } compactLeading: {
                // MARK: Compact Leading — Phase Icon
                Image(systemName: context.state.phaseIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor(for: context.attributes.patternColorHex))
            } compactTrailing: {
                // MARK: Compact Trailing — Live Timer
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(timerInterval: Date.now...context.state.phaseEndDate, countsDown: true)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .frame(minWidth: 28)
                        .foregroundStyle(accentColor(for: context.attributes.patternColorHex))
                }
            } minimal: {
                // MARK: Minimal — Tiny Phase Icon
                Image(systemName: context.state.phaseIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor(for: context.attributes.patternColorHex))
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<BreedySessionAttributes>) -> some View {
        let accent = accentColor(for: context.attributes.patternColorHex)
        
        HStack(spacing: 16) {
            // Left: Phase indicator with animated ring
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Circle()
                    .stroke(accent.opacity(0.3), lineWidth: 3)
                    .frame(width: 52, height: 52)
                
                Image(systemName: context.state.phaseIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(accent)
            }
            
            // Center: Phase name + timer
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.patternName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                if context.state.isPaused {
                    Text("Paused")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    HStack(spacing: 6) {
                        Text(context.state.phaseName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text("·")
                            .foregroundStyle(.secondary)
                        
                        Text(timerInterval: Date.now...context.state.phaseEndDate, countsDown: true)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(accent)
                    }
                }
            }
            
            Spacer()
            
            // Right: Cycle count
            VStack(spacing: 2) {
                Text("\(context.state.completedCycles)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("cycles")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(.black.opacity(0.7))
    }
    
    // MARK: - Dynamic Island Expanded Views
    
    @ViewBuilder
    private func phaseIconView(context: ActivityViewContext<BreedySessionAttributes>) -> some View {
        let accent = accentColor(for: context.attributes.patternColorHex)
        
        ZStack {
            Circle()
                .fill(accent.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: context.state.phaseIcon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
        }
    }
    
    @ViewBuilder
    private func cycleCountView(context: ActivityViewContext<BreedySessionAttributes>) -> some View {
        VStack(spacing: 1) {
            Text("\(context.state.completedCycles)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("cycles")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    @ViewBuilder
    private func expandedCenterView(context: ActivityViewContext<BreedySessionAttributes>) -> some View {
        VStack(spacing: 2) {
            Text(context.attributes.patternName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            
            if context.state.isPaused {
                Text("Paused")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text(context.state.phaseName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
    
    @ViewBuilder
    private func expandedBottomView(context: ActivityViewContext<BreedySessionAttributes>) -> some View {
        let accent = accentColor(for: context.attributes.patternColorHex)
        
        if context.state.isPaused {
            HStack {
                Image(systemName: "pause.fill")
                    .font(.system(size: 12))
                Text("Session paused — return to Breedy to continue")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
            .padding(.top, 4)
        } else {
            HStack(spacing: 12) {
                // Phase timer
                HStack(spacing: 4) {
                    Text("Phase")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(timerInterval: Date.now...context.state.phaseEndDate, countsDown: true)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                }
                
                Spacer()
                
                // Total session timer
                HStack(spacing: 4) {
                    Text("Session")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(timerInterval: Date.now...context.state.totalEndDate, countsDown: true)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Helpers
    
    private func accentColor(for hex: UInt) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
