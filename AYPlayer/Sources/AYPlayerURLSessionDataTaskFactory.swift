//
//  AYURLSessionDataTaskFactory.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 05/03/20.
//

import Foundation

protocol CustomURLSessionDataTask {
    func cancel()
    func resume()
}

extension URLSessionDataTask: CustomURLSessionDataTask {}

protocol URLSessionDataTaskFactory {
    func getDataTask(with url: URL,
                     timeout: TimeInterval,
                     completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> CustomURLSessionDataTask
}

struct AYPlayerURLSessionDataTaskFactory: URLSessionDataTaskFactory {
    func getDataTask(with url: URL,
                     timeout: TimeInterval,
                     completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> CustomURLSessionDataTask {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = timeout
        return URLSession(configuration: sessionConfig).dataTask(with: url, completionHandler: completionHandler)
    }
}
