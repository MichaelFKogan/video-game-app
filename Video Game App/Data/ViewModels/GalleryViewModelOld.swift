////
////  GalleryViewModel.swift
////  Video Game App
////
////  Created by Mike K on 8/17/25.
////
//
//import SwiftUI
//
//class GalleryViewModel: ObservableObject {
//    @Published var galleryImages: [String] = []
//    
//    @AppStorage("galleryImages") private var savedGalleryImagesData: Data = Data()
//    
//    init() {
//        loadGalleryImages()
//    }
//    
//    func loadGalleryImages() {
//        if let decoded = try? JSONDecoder().decode([String].self, from: savedGalleryImagesData), !decoded.isEmpty {
//            galleryImages = decoded
//        } else {
//            galleryImages = [] // or some defaults
//        }
//    }
//    
//    func saveGalleryImages() {
//        if let encoded = try? JSONEncoder().encode(galleryImages) {
//            savedGalleryImagesData = encoded
//        }
//    }
//    
//    func addNewImage(_ url: String) {
//        galleryImages.insert(url, at: 0)
//        saveGalleryImages()
//    }
//}
