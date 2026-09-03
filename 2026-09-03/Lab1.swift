// ============================================================
// MODULE 4: Swift Programming Fundamentals
// LAB — PNC Banking Domain Model
// Enterprise Mobile Application Development Bootcamp
// ============================================================
//
// OVERVIEW
// You are building the Swift data model layer for the PNC Mobile
// Banking application. This layer will be carried forward into
// Modules 6, 7, and 8 as the foundation of the real application.
//
// Every type you define here uses the Swift features from all
// three days of this module. Take time to read the full spec
// before writing any code.
//
// ESTIMATED TIME: 90–120 minutes
//
// ============================================================
// LAB SPEC
// ============================================================
//
// You will build five interconnected Swift types:
//
//   1. TransactionType enum
//   2. TransactionStatus enum
//   3. Transaction struct
//   4. Account class
//   5. AccountAnalytics struct
//
// And three protocols:
//
//   A. Summarizable       — any type that can produce a summary string
//   B. AccountOperations  — deposit, withdraw, transfer
//   C. AnalyticsProvider  — compute basic financial metrics
//
// The lab ends with an error handling system and a generic
// result reporting function that ties everything together.
//
// Read each section completely before implementing it.
// ============================================================

import Foundation


// ============================================================
// SECTION 1: Enumerations
// ============================================================

// TODO 1A: TransactionType
// Conform to: String, CaseIterable, Codable
// Cases:     credit, debit, transfer, fee
// Add computed property: isExpense: Bool
//   → true for .debit and .fee, false otherwise
enum TransactionType: String, CaseIterable, Codable {
    case credit, debit, transfer, fee
    
    var isExpense: Bool {
        switch self {
        case .debit, .fee: return true
        default: return false
        }
    }
}

// TODO 1B: TransactionStatus
// Conform to: String, Codable
// Cases:     pending, completed, failed, cancelled
// Add computed property: isTerminal: Bool
//   → true for .completed, .failed, .cancelled
//   → false for .pending (can still change)
enum TransactionStatus: String, Codable {
    case pending, completed, failed, cancelled
    
    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled: return true
        case .pending: return false
        }
    }
}

// ============================================================
// SECTION 2: Transaction Struct
// ============================================================

// TODO 2: Define struct Transaction conforming to:
//   Identifiable, Codable, Equatable, Hashable, Summarizable (see Section 4A)
//
// Stored properties:
//   id: String                (unique identifier, default to UUID().uuidString)
//   date: Date
//   amount: Double            (always positive — type determines direction)
//   description: String
//   type: TransactionType
//   status: TransactionStatus (default: .completed)
//   category: String?
//   merchantName: String?
//
// Computed properties:
//   formattedAmount: String
//     → "-$X.XX" for expenses (type.isExpense == true)
//     → "+$X.XX" for income/credit
//
//   formattedDate: String
//     → Use DateFormatter with dateStyle: .medium, timeStyle: .short
//
//   resolvedCategory: String
//     → Returns category if non-nil, "Uncategorized" otherwise
//
// Custom initializer (all params except id, status, category, merchantName
// should be required; the rest should have defaults):
//   init(date:amount:description:type:status:category:merchantName:)
struct Transaction: Identifiable, Codable, Equatable, Hashable, Summarizable {
    let id: String
    let date: Date
    let amount: Double
    var description: String
    let type: TransactionType
    var status: TransactionStatus = .completed
    let category: String?
    let merchantName: String?
    
    var formattedAmount: String {
        return "\(type.isExpense ? "-" : "+")$\(String(format: "%.2f", amount))"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var resolvedCategory: String {
        category ?? "Uncategorized"
    }
    
    var summary: String {
        "\(formattedDate) \(formattedAmount) \(resolvedCategory) \(description)"
    }
}

// ============================================================
// SECTION 3: Account Class
// ============================================================

// TODO 3A: Define protocol AccountOperations (see Section 4B)
// before defining Account, because Account will conform to it.
// (Define the protocol in Section 4B, then add conformance to Account here)

// TODO 3B: Define class BankAccount conforming to:
//   Identifiable, AccountOperations, Summarizable
//
// Stored properties:
//   id: String
//   accountNumber: String
//   accountType: String          (e.g., "CHECKING", "SAVINGS")
//   nickname: String?
//   var balance: Double
//   var availableBalance: Double
//   let currency: String         (default "USD")
//   let isActive: Bool           (default true)
//   var transactions: [Transaction]
//
// Computed properties:
//   displayName: String          → nickname if non-nil, else accountType.capitalized
//   maskedAccountNumber: String  → "****" + last 4 digits
//   formattedBalance: String     → "$X.XX"
//   recentTransactions: [Transaction]  → last 5, sorted by date descending
//   pendingCount: Int            → count of transactions with status .pending
//
// Designated initializer:
//   init(id:accountNumber:accountType:nickname:initialBalance:currency:isActive:)
//
// Implement AccountOperations (see Section 4B for the protocol requirements).
// Use the AccountError enum from Section 4C.
//
// Also add:
//   func addTransaction(_ transaction: Transaction)
//     → appends to transactions AND updates balance:
//       if transaction.type.isExpense: balance -= transaction.amount
//       else:                          balance += transaction.amount
//       Update availableBalance to match balance.
class BankAccount: Identifiable, AccountOperations, Summarizable {
    let id: String
    let accountNumber: String
    let accountType: String
    var nickname: String?
    var balance: Double
    var availableBalance: Double
    let currency: String
    let isActive: Bool
    var transactions: [Transaction]
    
    init(id: String, accountNumber: String, accountType: String, nickname: String?, balance: Double, currency: String="USD", isActive: Bool=true) {
        self.id = id
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.nickname = nickname
        self.balance = balance
        self.availableBalance = balance
        self.currency = currency
        self.isActive = isActive
        self.transactions = []
    }
    
    var displayName: String {
        return nickname ?? accountType.capitalized
    }
    var maskedAccountNumber: String {
        return "****\(accountNumber.suffix(4))"
    }
    var formattedBalance: String {
        return String(format: "$%.2f", balance)
    }
    var recentTransactions: [Transaction] {
        return Array(transactions.sorted(by: { $0.date > $1.date }).prefix(5))
    }
    var pendingCount: Int {
        return transactions.filter {$0.status == .pending}.count
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        if transaction.type.isExpense {
            balance -= transaction.amount
            availableBalance -= transaction.amount
        } else {
            balance += transaction.amount
            availableBalance += transaction.amount
        }
    }
    
    // Summarizable:
    var summary: String {
        return "\(displayName) \(maskedAccountNumber): \(formattedBalance)"
    }
    
    // Account Operations:
    func deposit(amount: Double) throws {
        guard amount > 0 else {
            throw AccountOperationsError.invalidAmount
        }
        guard isActive else {
            throw AccountOperationsError.accountInactive
        }
        balance += amount
        availableBalance += amount
    }
    
    func withdraw(amount: Double) throws {
        guard amount > 0 else {
            throw AccountOperationsError.invalidAmount
        }
        guard isActive else {
            throw AccountOperationsError.accountInactive
        }
        guard availableBalance >= amount else {
            throw AccountOperationsError.insufficientFunds(available: availableBalance, required: amount)
        }
        balance -= amount
        availableBalance -= amount
    }
    
    func transfer(amount: Double, to destination: BankAccount) throws {
        guard self.id != destination.id else {
            throw AccountOperationsError.transferToSameAccount
        }
        try withdraw(amount: amount)
        try destination.deposit(amount: amount)
    }
}
    


// ============================================================
// SECTION 4: Protocols
// ============================================================

// TODO 4A: Summarizable protocol
//   Required: var summary: String { get }
//   Default implementation via extension: func printSummary() — prints summary
protocol Summarizable {
    var summary: String { get }
}

extension Summarizable {
    func printSummary() {
        print(summary)
    }
}

// TODO 4B: AccountOperations protocol
//   func deposit(amount: Double) throws
//   func withdraw(amount: Double) throws
//   func transfer(amount: Double, to destination: BankAccount) throws
//
// These methods throw AccountOperationsError (define in Section 4C).
protocol AccountOperations {
    func deposit(amount: Double) throws
    func withdraw(amount: Double) throws
    func transfer(amount: Double, to destination: BankAccount) throws
}
// TODO 4C: AccountOperationsError enum conforming to LocalizedError
// Cases:
//   invalidAmount
//   insufficientFunds(available: Double, required: Double)
//   accountInactive
//   transferToSameAccount
//   dailyLimitExceeded(limit: Double)
//
// Each case should have a meaningful errorDescription.
enum AccountOperationsError: LocalizedError {
    case invalidAmount
    case insufficientFunds(available: Double, required: Double)
    case accountInactive
    case transferToSameAccount
    case dailyLimitExceeded(limit: Double)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid amount"
        case .insufficientFunds(available: let a, required: let r):
            return "Insufficient funds. Avaialable: $\(String(format: "%.2f", a)) | Required: $\(String(format: "%.2f", r))"
        case .accountInactive:
            return "Account Inactive"
        case .transferToSameAccount:
            return "Attempted to transfer to same account"
        case .dailyLimitExceeded(limit: let l):
            return "Daily limit of #\(String(format: "%.2f", l)) exceeded"
        }
    }
}

// ============================================================
// SECTION 5: Analytics
// ============================================================

// TODO 5A: AnalyticsProvider protocol
//   var totalCredits: Double { get }
//   var totalDebits: Double { get }
//   var netFlow: Double { get }         // credits - debits
//   var largestTransaction: Transaction? { get }
//   func monthlyTotal(month: Int, year: Int) -> Double
//   func transactionsByCategory() -> [String: [Transaction]]
protocol AnalyticsProvider {
    var totalCredits: Double { get }
    var totalDebits: Double { get }
    var netFlow: Double { get }
    var largestTransaction: Transaction? { get }
    func monthlyTotal(month: Int, year: Int) -> Double
    func transactionsByCategory() -> [String: [Transaction]]
}

// TODO 5B: AccountAnalytics struct
// Stored property: transactions: [Transaction]
// Conform to AnalyticsProvider.
// Implement each requirement.
//
// Tips:
//   totalCredits: use .filter { !$0.type.isExpense }.reduce(0) { $0 + $1.amount }
//   transactionsByCategory: group by resolvedCategory using a Dictionary
//     (hint: use Dictionary(grouping:by:))
//   monthlyTotal: filter by Calendar.current month/year components and sum expense amounts
struct AccountAnalytics: AnalyticsProvider {
    var transactions: [Transaction]
    
    var totalCredits: Double {
        transactions.filter { !$0.type.isExpense}.reduce(0) { $0 + $1.amount }
    }
    var totalDebits: Double {
        transactions.filter { $0.type.isExpense }.reduce(0) { $0 + $1.amount}
    }
    var netFlow: Double {
        totalCredits - totalDebits
    }
    var largestTransaction: Transaction? {
        transactions.max(by: { $0.amount < $1.amount })
    }
    func monthlyTotal(month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        return transactions
            .filter { $0.type.isExpense }
            .filter { calendar.component(.month, from: $0.date) == month }
            .filter { calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.amount}
    }
    func transactionsByCategory() -> [String: [Transaction]] {
        Dictionary(grouping: transactions, by: { $0.resolvedCategory })
    }
}

// ============================================================
// SECTION 6: Generic Result Reporter
// ============================================================

// TODO 6: Write a generic function:
//   func reportResults<T: Summarizable>(_ items: [T], title: String)
//
// It should:
//   1. Print a header line: "=== [title] ==="
//   2. Print the item count: "[N] items"
//   3. Call printSummary() on each item
//   4. Print a footer: "=== End of [title] ==="
//
// The function must work for any type conforming to Summarizable —
// including both Transaction and BankAccount.
func reportResults<T: Summarizable>(_ items: [T], title: String) {
    print("===\(title)===")
    print("\(items.count) items")
    items.forEach { $0.printSummary() }
    print("===End of \(title)===")
}

// ============================================================
// SECTION 7: INTEGRATION TEST — Tie it all together
// ============================================================

// TODO 7: Write a function named runlabDemo() that does the following:
func runLabDemo() {
    
    // 7A: Create at least two BankAccount instances:
    //   - A checking account with $3,500 initial balance
    //   - A savings account with $12,000 initial balance
    let checking = BankAccount(id: "ACC_001", accountNumber: "1234", accountType: "Checking", nickname: "Mark's Checking", balance: 3_500)
    let savings = BankAccount(id: "ACC_002", accountNumber: "5678", accountType: "Savings", nickname: "Helly's Savings", balance: 12_000)
    
    // 7B: Create at least five Transaction instances across different types
    //   and add them to the checking account using addTransaction(_:)
    //   Include: one credit, two debits, one fee, one transfer
    //   Verify the balance updates correctly after each addition.
    let credit = Transaction(id: "T_001", date: Date(), amount: 1_000, description: "Paycheck", type: .credit, category: "Income", merchantName: nil)
    let debit1 = Transaction(id: "T_002", date: Date(), amount: 18.48, description: "Lunch", type: .debit, category: "Expenses", merchantName: "Wendy's")
    let debit2 = Transaction(id: "T_003", date: Date(), amount: 162.77, description: "Groceries", type: .debit, category: "Expenses", merchantName: "Aldi")
    let fee = Transaction(id: "T_004", date: Date(), amount: 19.99, description: "Netflix monthly charge", type: .fee, category: "Fees", merchantName: "Netflix")
    let transfer = Transaction(id: "T_005", date: Date(), amount: 200.00, description: "Transfer to savings", type: .transfer, category: "Transfer", merchantName: nil)
    
    for transaction in [credit, debit1, debit2, fee, transfer] {
        checking.addTransaction(transaction)
        print("\(transaction.description) | Balance: \(checking.formattedBalance)")
    }
    
    // 7C: Demonstrate error handling:
    //   - Try to withdraw more than the available balance → catch insufficientFunds
    //   - Try to deposit a negative amount → catch invalidAmount
    //   - Try to transfer to the same account → catch transferToSameAccount
    //   Print the localized error description for each caught error.
    do {
        try checking.withdraw(amount: 10_000_000_000)
    } catch let e as AccountOperationsError {
        print("Error: \(e.localizedDescription)")
    } catch {
        print(error)
    }
    
    do {
        try checking.deposit(amount: -27)
    } catch let e as AccountOperationsError {
        print("Error: \(e.localizedDescription)")
    } catch {
        print(error)
    }
    
    do {
        try checking.transfer(amount: 123, to: checking)
    } catch let e as AccountOperationsError {
        print("Error: \(e.localizedDescription)")
    } catch {
        print(error)
    }
    
    // 7D: Create an AccountAnalytics instance with the checking account's transactions.
    //   Print:
    //   - Total credits
    //   - Total debits
    //   - Net flow
    //   - The description and amount of the largest transaction
    //   - The transactions grouped by category (print each category and count)
    let analytics = AccountAnalytics(transactions: checking.transactions)
    print("Total credits: \(analytics.totalCredits)")
    print("Total debits: \(analytics.totalDebits)")
    print("Net flow: \(analytics.netFlow)")
    print("Largest transaction: \(analytics.largestTransaction?.description ?? "None")")
    for (category, transaction) in analytics.transactionsByCategory() {
        print("\(category): \(transaction.count) transactions")
    }
    
    // 7E: Call reportResults with the checking account's transactions, title: "Checking Transactions"
    //   Call reportResults with [checkingAccount, savingsAccount], title: "All Accounts"
    reportResults(checking.transactions, title: "Checking transactions")
    reportResults([checking, savings], title: "All Accounts")
    // 7F: Demonstrate value vs. reference semantics:
    //   Copy one Transaction (struct) into a new variable. Modify the copy's description.
    //   Show the original is unchanged.
    //   Assign the checking account (class) to a new variable. Deposit $100 through the alias.
    //   Show both variables reflect the updated balance.
    var transactionCopy = credit
    transactionCopy.description = "Welfare check"
    print("Original: \(credit.description)")
    print("Copy: \(transactionCopy.description)")
    
    let checkingCopy = checking
    try? checkingCopy.deposit(amount: 100)
    print("Original: \(checking.balance)")
    print("Copy: \(checkingCopy.balance)")
}
// TODO: Call runlabDemo() at the bottom of the file.
runLabDemo()

// ============================================================
// END OF LAB
// ============================================================
//
// SELF-ASSESSMENT CHECKLIST
// Before submitting, verify:
//   [ ] All five types compile without warnings
//   [ ] runlabDemo() runs to completion with no crashes
//   [ ] Each error case in 7C is handled and prints a clear message
//   [ ] Struct copy semantics are correctly demonstrated in 7F
//   [ ] Class reference semantics are correctly demonstrated in 7F
//   [ ] reportResults works for both Transaction and BankAccount
//   [ ] Analytics produce correct totals matching your transactions
// ============================================================
