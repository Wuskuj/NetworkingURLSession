//
//  DataProvider.swift
//  Networking
//
//  Created by Филипп on 1/30/20.
//  Copyright © 2020 Alexey Efimov. All rights reserved.
//

import UIKit

class DataProvider: NSObject {
    private var downloadTask: URLSessionDownloadTask!
    var fileLocation: ((URL) -> ())?
    var onProgress: ((Double) -> ())?
    
    private lazy var bgSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "ru.swiftbook.Networking")//поведение сессии при загрузке и выгрузке данных
        config.isDiscretionary = true// для больших данных эпл говорит ставить true
        config.sessionSendsLaunchEvents = true//по завершению загрузке данных приложение запуститься в фоновом режиме
        config.waitsForConnectivity = true //Ожидание подключения к сети(по умолчанию true)
        config.timeoutIntervalForResource = 300 //Время ожидания сети в сек
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    
    
    func startDownload() {
        if let url = URL(string: "https://speed.hetzner.de/100MB.bin") {
            downloadTask = bgSession.downloadTask(with: url)//создаем экземпляр urlSession
            downloadTask.earliestBeginDate = Date().addingTimeInterval(3)//гарантирует что загрузка начнется не ранее чем через 3 сек после создания задачи
            downloadTask.countOfBytesClientExpectsToSend = 512// наиболее вероятная верхняя границу числа байтов, которую клиент ожидает отправить
            downloadTask.countOfBytesClientExpectsToReceive = 100 * 1024 * 1024//определяет наиболее вероятню границу байтов, которую клиент ожидает получить
            downloadTask.resume()
        }
    }
    
    func stopDownload() {
        downloadTask.cancel()
    }
}


extension DataProvider : URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard
                let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.bgSessionCompletionHandler
                else {return}
            appDelegate.bgSessionCompletionHandler = nil
            completionHandler()//говорит о том , что задача завершилась
        }
    }//вызывается по завершению всех фоновых задач помещенных в очередь
}


extension DataProvider: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Did finish downloading \(location.absoluteString)")
        DispatchQueue.main.async {
            self.fileLocation?(location) //путь к временному файлу
        }
    }

    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown else { return }
        let progress = Double(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        print("Download progress: \(progress)")
        
        DispatchQueue.main.async {
            self.onProgress?(progress)
        }
    }

}
