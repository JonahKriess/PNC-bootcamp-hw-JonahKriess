//
//  ProductList.swift
//  SwiftUITwoViews
//
//  Created by user302023 on 9/8/26.
//

import SwiftUI

struct ProductList: View {
    
    @State private var products: [Product] = []
    
    var body: some View {
        NavigationStack {
            List(products) { prod in
                NavigationLink(value: prod) {
                    HStack {
                        Text(prod.name)
                        Text(prod.color)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(Text("Products"))
            .navigationDestination(for: Product.self) {
                selectedItem in
                ProductDetails(product: selectedItem)
            }
        }
        .task {
            loadData()
        }
    }
    
    func loadData() {
        products = [
            Product(id: 101, name: "Mouse", productNumber: "PD-327534", color: "Black", listPrice: 29.99),
            Product(id: 102, name: "Keyboard", productNumber: "PD-723466", color: "White", listPrice: 59.99),
            Product(id: 103, name: "Chassis", productNumber: "PD-994563", color: "Gray", listPrice: 114.99),
            Product(id: 104, name: "WiiU", productNumber: "PD-342312", color: "Black", listPrice: 149.99),
            Product(id: 105, name: "iPad", productNumber: "PD-351299", color: "Silver", listPrice: 599.99)
        ]
    }
}


#Preview {
    ProductList()
}
