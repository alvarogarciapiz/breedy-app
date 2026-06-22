import SwiftUI
import Observation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable {
    case monthly = "breedy_monthly"
    case annual = "breedy_annual"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual:  return "Annual"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .annual:  return "$29.99"
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .monthly: return "$4.99/mo"
        case .annual:  return "$2.49/mo"
        }
    }
    
    var savingsLabel: String? {
        switch self {
        case .monthly: return nil
        case .annual:  return "Save 50%"
        }
    }
    
    var billingDescription: String {
        switch self {
        case .monthly: return "Billed monthly"
        case .annual:  return "Billed annually"
        }
    }
}

// MARK: - Subscription Manager

@Observable
@MainActor
final class SubscriptionManager {
    
    // MARK: - Subscription State
    
    @ObservationIgnored
    @AppStorage("isSubscribed") private var _isSubscribed = false
    
    @ObservationIgnored
    @AppStorage("subscriptionTier") private var _subscriptionTier: String = ""
    
    @ObservationIgnored
    @AppStorage("subscriptionDate") private var _subscriptionDate: Double = 0
    
    var isSubscribed: Bool {
        get { _isSubscribed }
        set { _isSubscribed = newValue }
    }
    
    var currentTier: SubscriptionTier? {
        SubscriptionTier(rawValue: _subscriptionTier)
    }
    
    var subscriptionDate: Date? {
        _subscriptionDate > 0 ? Date(timeIntervalSince1970: _subscriptionDate) : nil
    }
    
    // MARK: - Loading State
    
    private(set) var isPurchasing = false
    private(set) var purchaseError: String?
    
    // MARK: - Purchase (StoreKit 2 Stub)
    // TODO: Replace with real StoreKit 2 Product.purchase() when App Store Connect is configured
    
    func purchase(_ tier: SubscriptionTier) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        
        // Simulate a brief network delay
        try? await Task.sleep(for: .milliseconds(800))
        
        // In production, this would:
        // 1. Fetch Product from StoreKit 2
        // 2. Call product.purchase()
        // 3. Verify the transaction
        // 4. Update subscription state
        
        _isSubscribed = true
        _subscriptionTier = tier.rawValue
        _subscriptionDate = Date().timeIntervalSince1970
        
        isPurchasing = false
        return true
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async -> Bool {
        isPurchasing = true
        purchaseError = nil
        
        try? await Task.sleep(for: .milliseconds(500))
        
        // In production, this would call AppStore.sync() and check Transaction.currentEntitlements
        // For now, check if we have a stored subscription
        if _subscriptionTier.isEmpty {
            purchaseError = "No previous purchases found"
            isPurchasing = false
            return false
        }
        
        _isSubscribed = true
        isPurchasing = false
        return true
    }
    
    // MARK: - Subscription Info
    
    var statusText: String {
        guard isSubscribed, let tier = currentTier else {
            return "Not subscribed"
        }
        return "\(tier.displayName) — Active"
    }
    
    var memberSince: String? {
        guard let date = subscriptionDate else { return nil }
        return date.formatted(.dateTime.month(.wide).year())
    }
    
    // MARK: - Features
    
    static let premiumFeatures: [(icon: String, title: String, subtitle: String)] = [
        ("infinity", "Unlimited Sessions", "Breathe as much as you want, any time"),
        ("wind", "All Breathing Patterns", "8 science-backed techniques included"),
        ("slider.horizontal.3", "Custom Pattern Builder", "Create your perfect breathing rhythm"),
        ("chart.bar.fill", "Progress & Insights", "Track streaks, XP, and daily trends"),
        ("face.smiling.fill", "Breedy Companion", "Daily check-ins and personalized guidance"),
        ("heart.fill", "Apple Health Sync", "Automatically log mindful minutes"),
    ]
}
