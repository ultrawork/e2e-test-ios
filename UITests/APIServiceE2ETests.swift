import XCTest
import CryptoKit

final class APIServiceE2ETests: XCTestCase {

    // MARK: - Configuration

    private var baseURL: String {
        ProcessInfo.processInfo.environment["API_URL"]
            ?? ProcessInfo.processInfo.environment["BASE_URL"]
            ?? "http://localhost:4000"
    }

    private var jwtSecret: String {
        ProcessInfo.processInfo.environment["JWT_SECRET"]
            ?? "e2e-test-secret-key-ultrawork"
    }

    // MARK: - JWT Helper

    /// Generates a valid HS256 JWT signed with the test secret.
    private func generateJWT() -> String {
        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let payload = #"{"sub":"1","email":"e2e@test.com","iat":1700000000,"exp":2000000000}"#

        let headerB64 = base64URLEncode(Data(header.utf8))
        let payloadB64 = base64URLEncode(Data(payload.utf8))

        let signingInput = "\(headerB64).\(payloadB64)"
        let key = SymmetricKey(data: Data(jwtSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(signingInput.utf8),
            using: key
        )
        let signatureB64 = base64URLEncode(Data(signature))

        return "\(signingInput).\(signatureB64)"
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - SC-2: GET /notes with valid Bearer token returns correct Note format

    func testSC02_fetchNotesWithValidBearerTokenReturnsCorrectFormat() async throws {
        let token = generateJWT()

        // First, create a note to ensure the list is non-empty
        let createURL = URL(string: "\(baseURL)/notes")!
        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "POST"
        createRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createRequest.httpBody = #"{"text":"E2E Test Note"}"#.data(using: .utf8)
        _ = try? await URLSession.shared.data(for: createRequest)

        // GET /notes with valid token
        let url = URL(string: "\(baseURL)/notes")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)

        XCTAssertEqual(httpResponse.statusCode, 200, "GET /notes with valid token should return 200")

        // Response must be a JSON array
        let json = try JSONSerialization.jsonObject(with: data)
        let array = try XCTUnwrap(json as? [[String: Any]], "Response should be a JSON array of objects")

        // Verify each element has id (number) and text (string) matching Note model
        for note in array {
            XCTAssertNotNil(note["id"], "Each note should have an 'id' field")
            XCTAssertTrue(note["id"] is NSNumber, "Note 'id' should be a number")
            XCTAssertNotNil(note["text"] as? String, "Each note should have a 'text' string field")
        }
    }

    // MARK: - SC-3: GET /notes without Authorization returns 401

    func testSC03_fetchNotesWithoutAuthorizationReturns401() async throws {
        let url = URL(string: "\(baseURL)/notes")!
        let request = URLRequest(url: url)

        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)

        XCTAssertEqual(
            httpResponse.statusCode, 401,
            "GET /notes without Authorization header should return 401"
        )
    }
}
