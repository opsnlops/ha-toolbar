//
//  HomeAssistantAPIClient.swift
//  HomeAssistantWidget
//
//  Created by Claude Code
//

import Foundation

struct HomeAssistantAPIClient {
    private let baseURL: String
    private let authToken: String
    private let port: Int
    private let useTLS: Bool

    init(hostname: String, port: Int, useTLS: Bool, authToken: String) {
        self.baseURL = hostname
        self.port = port
        self.useTLS = useTLS
        self.authToken = authToken
    }

    private var apiURL: URL? {
        var components = URLComponents()
        components.scheme = useTLS ? "https" : "http"
        components.host = baseURL
        components.port = port
        components.path = "/api/states"
        return components.url
    }

    /// Fetch the current state of an entity
    func fetchEntityState(_ entityID: String) async throws -> String {
        guard let baseURL = apiURL else {
            throw HomeAssistantError.invalidURL
        }

        let entityURL = baseURL.appendingPathComponent(entityID)
        var request = URLRequest(url: entityURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HomeAssistantError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw HomeAssistantError.httpError(httpResponse.statusCode)
        }

        let entityState = try JSONDecoder().decode(EntityStateResponse.self, from: data)
        return entityState.state
    }

    /// Fetch multiple entities in parallel
    func fetchSensorData(
        temperatureEntity: String,
        windSpeedEntity: String,
        rainAmountEntity: String,
        temperatureMaxEntity: String?,
        temperatureMinEntity: String?,
        humidityEntity: String?,
        windSpeedMaxEntity: String?,
        pm25Entity: String?,
        lightLevelEntity: String?,
        aqiEntity: String?,
        windDirectionEntity: String?
    ) async throws -> SensorSnapshot {
        // Fetch core entities in parallel
        async let temperature = fetchEntityState(temperatureEntity)
        async let windSpeed = fetchEntityState(windSpeedEntity)
        async let rainAmount = fetchEntityState(rainAmountEntity)

        // Fetch optional entities
        let temperatureMax: String?
        if let maxEntity = temperatureMaxEntity, !maxEntity.isEmpty {
            temperatureMax = try? await fetchEntityState(maxEntity)
        } else {
            temperatureMax = nil
        }

        let temperatureMin: String?
        if let minEntity = temperatureMinEntity, !minEntity.isEmpty {
            temperatureMin = try? await fetchEntityState(minEntity)
        } else {
            temperatureMin = nil
        }

        let humidity: String?
        if let humEntity = humidityEntity, !humEntity.isEmpty {
            humidity = try? await fetchEntityState(humEntity)
        } else {
            humidity = nil
        }

        let windSpeedMaxStr: String?
        if let maxEntity = windSpeedMaxEntity, !maxEntity.isEmpty {
            windSpeedMaxStr = try? await fetchEntityState(maxEntity)
        } else {
            windSpeedMaxStr = nil
        }

        let pm25Str: String?
        if let pm25Ent = pm25Entity, !pm25Ent.isEmpty {
            pm25Str = try? await fetchEntityState(pm25Ent)
        } else {
            pm25Str = nil
        }

        let lightLevelStr: String?
        if let lightEnt = lightLevelEntity, !lightEnt.isEmpty {
            lightLevelStr = try? await fetchEntityState(lightEnt)
        } else {
            lightLevelStr = nil
        }

        let aqiStr: String?
        if let aqiEnt = aqiEntity, !aqiEnt.isEmpty {
            aqiStr = try? await fetchEntityState(aqiEnt)
        } else {
            aqiStr = nil
        }

        let windDirStr: String?
        if let windDirEnt = windDirectionEntity, !windDirEnt.isEmpty {
            windDirStr = try? await fetchEntityState(windDirEnt)
        } else {
            windDirStr = nil
        }

        let (tempStr, windStr, rainStr) = try await (temperature, windSpeed, rainAmount)

        return SensorSnapshot(
            outsideTemperature: Double(tempStr) ?? 0.0,
            windSpeed: Double(windStr) ?? 0.0,
            rainAmount: Double(rainStr) ?? 0.0,
            temperatureMax: temperatureMax != nil ? Double(temperatureMax!) ?? 0.0 : 0.0,
            temperatureMin: temperatureMin != nil ? Double(temperatureMin!) ?? 0.0 : 0.0,
            humidity: humidity != nil ? Double(humidity!) ?? 0.0 : 0.0,
            windSpeedMax: windSpeedMaxStr != nil ? Double(windSpeedMaxStr!) ?? 0.0 : 0.0,
            pm25: pm25Str != nil ? Double(pm25Str!) ?? 0.0 : 0.0,
            lightLevel: lightLevelStr != nil ? Double(lightLevelStr!) ?? 0.0 : 0.0,
            aqi: aqiStr != nil ? Double(aqiStr!) ?? 0.0 : 0.0,
            windDirection: windDirStr ?? "",
            lastUpdated: Date()
        )
    }
}

// MARK: - Response Models

struct EntityStateResponse: Codable {
    let state: String
    let entityId: String
    let lastChanged: String?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case state
        case entityId = "entity_id"
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
    }
}

// MARK: - Errors

enum HomeAssistantError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case missingConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Home Assistant URL"
        case .invalidResponse:
            return "Invalid response from Home Assistant"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .missingConfiguration:
            return "Home Assistant not configured"
        }
    }
}
