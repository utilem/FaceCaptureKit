//
//  AgeVerificationService.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import Foundation

// MARK: - Result

public struct AgeVerificationResult: Codable, Sendable {
    public let isVerified: Bool
    public let estimatedAge: Int?
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case isVerified = "verified"
        case estimatedAge
        case message
    }
}

// MARK: - Errors

public enum AgeVerificationError: LocalizedError, Sendable {
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error (\(code))"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}

// MARK: - Protocol

public protocol AgeVerificationService: Sendable {
    func verify(imageData: Data) async throws -> AgeVerificationResult
}

// MARK: - Live Implementation

public final class LiveAgeVerificationService: AgeVerificationService {
    private let endpointURL: URL
    private let session: URLSession

    public init(endpointURL: URL, session: URLSession = .shared) {
        self.endpointURL = endpointURL
        self.session = session
    }

    public func verify(imageData: Data) async throws -> AgeVerificationResult {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgeVerificationError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AgeVerificationError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(AgeVerificationResult.self, from: data)
        } catch {
            throw AgeVerificationError.decodingFailed
        }
    }
}
