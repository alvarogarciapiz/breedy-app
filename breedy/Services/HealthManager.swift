import HealthKit
import Observation

// MARK: - Health Manager

@Observable
@MainActor
final class HealthManager {
    static let shared = HealthManager()
    
    private let healthStore = HKHealthStore()
    private(set) var isAuthorized: Bool = false
    private(set) var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return false
        }
        
        let typesToWrite: Set<HKSampleType> = [mindfulType]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
            let status = healthStore.authorizationStatus(for: mindfulType)
            isAuthorized = status == .sharingAuthorized
            return isAuthorized
        } catch {
            return false
        }
    }
    
    // MARK: - Write Mindful Minutes
    
    func saveMindfulSession(startDate: Date, endDate: Date) async -> Bool {
        guard isAuthorized else { return false }
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return false
        }
        
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        
        do {
            try await healthStore.save(sample)
            return true
        } catch {
            return false
        }
    }
}
