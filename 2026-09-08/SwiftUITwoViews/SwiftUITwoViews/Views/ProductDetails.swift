//
//  ProductDetails.swift
//  SwiftUITwoViews
//
//  Created by user302023 on 9/8/26.
//

import SwiftUI

struct ProductDetails: View {
    
    var product: Product
    
    var body: some View {
        
        @Bindable var prodBinding = product
        
        VStack {
            Text("\(product.name)")
                .font(Font.largeTitle)
                .fontWeight(.black)
            Text("ID: \(product.id) | Number: \(product.productNumber)")
            Text("Color: \(product.color)")
                .font(Font.title)
            Text("$\(String(format: "%.2f", product.listPrice))")
                .font(.title)
            
        }
        .padding()

    }

}

#Preview {
    ProductDetails(product: Product(id: 101, name: "Mouse", productNumber: "PD-327534", color: "Black", listPrice: 29.99))
}
