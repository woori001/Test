//
//  BeaconService.swift
//  BeaconTest
//
//  Created by 우리시스템MAC on 2020/04/09.
//  Copyright © 2020 Facebook. All rights reserved.
//


import Foundation
import UIKit
import CoreLocation
import CoreBluetooth
import CoreMotion
import NotificationCenter
import SystemConfiguration
import AudioToolbox
import CoreGraphics

typealias Parameters = [String: String]

@objc(BeaconService)
class BeaconService: NSObject, CLLocationManagerDelegate {
  
  // 1015
  var startLimit = 0
  
  var CVA: Double = 0
  
  //현재 CVA값
  var NextValue: Double = 0
  
  //이전 CVA값
  var PreValue: Double = 0
  
  
  //기본 디폴트 PreValue - NextValue 절대값
  var DefaltAbsValue: Double = 0.2
  
  //accelomtor 실제 값
  var data_x = 0.0
  var data_y = 0.0
  var data_z = 0.0
  
  //Gyro 실제 값
  var data_roll = 0.0
  var data_pitch = 0.0
  var data_yaw = 0.0
  
  //Gyro 값 생길때마다 최대 2까지 증가시킬 것
  var gycount:Int = 0
  
  //KalmanFilter Gyro 값
  var kal_Roll :Double = 0.0
  var kal_Pitch :Double = 0.0
  var kal_Yaw :Double = 0.0
  
  var LIMIT_MAX :Double = 0.5
  var LIMIT_MIN :Double = -0.5
  
  var accel_count:Int = 0
  var gyro_count:Int = 0
  
  //절대값을 구하기 위한 현재 Sensor Value
  var CurrentRoll:Double = 0
  var CurrentPitch:Double = 0
  var CurrentYaw:Double = 0
  
  var RollResultCount:Int = 0
  var PitchResultCount:Int = 0
  var YawResultCount:Int = 0
  
  var PreRollCount:Int = 0
  var PrePitchCount:Int = 0
  var PreYawCount:Int = 0
  
  var Pre_1_Check:Bool = false
  var Pre_2_Check:Bool = false
  var Pre_3_Check:Bool = false
  var Current_Check:Bool = false
  
  //Timer Count
  var counter = 0
  var lobbyCount = 0
  //    var Major1Count = 0
  var AccelBeaconGet = 0
  var endCheckCount = 0
  var startCheckCount = 0
  var accelCount = 0
  
  //Timer
  var timer = Timer()
  var lobbyTimer = Timer()
  var endBeaconTimer = Timer()
  var startBeaconTimer = Timer()
  var accelTimer = Timer()
  
  var i:Int = 0
  var a:Int = 0
  var gyrosavecount:Int = 0
  
  //SensorSeq
  var SensorSeq = 0
  var BeaconSeq = 0
  
  //SensorDelay
  var AccelDelay = 0
  var BeaconDelay = 0
  var GyroDelay = 0
  
  //MapVC data
  var carNumberData :String = ""
  var mapIdData :String = ""
  var lastParkingTimeData :String = ""
  var areaData :String = ""
  var xData :Double = 0
  var yData :Double = 0
  
  var parkingTime :String = ""
  
  //SignInVC data
  var userId :String = ""
  var dong :String = ""
  var ho :String = ""
  
  var ResultCount = 0
  var Result = ""
  
  //출입 & 출차 CheckPermission
  var AccelBeaconPermission :Bool = false
  var StartBeaconCheck :Bool = false
  var gyroSaveFlag :Bool = false
  var counterFlag :Bool = false
  var sensorFlag :Bool = false
  var networkPerMission :Bool = false
  var useFlag :Bool = true
  var sendDataPermission :Bool = false
  var lobbyStart: Bool = false
  var endBeaconTimerCheck: Bool = false
  var startBeaconTimerCheck: Bool = false
  
  var ROLLCOUNT:Int = 0
  var PICTHCOUNT:Int = 0
  var YAWCOUNT:Int = 0
  
  //accele 5로 나눌것
  var acceleDivision = 0
  
  var accelcount = 0
  
  //Minor 값중에 32768 넘는애들
  var ModifiMinor = 0
  
  var Result_location = 0
  
  //날짜 및 시간
  let date = Date()
  let dateFormatter = DateFormatter()
  
  var locationManager: CLLocationManager!
  let motion = CMMotionManager()
  
  //Beacon Permission
  var beaconMajor1: Bool = false      //로비
  var beaconMajor2: Bool = false      //아파트 정문
  var beaconMajor3: Bool = false      //엘레베이터
  var beaconMajor6: Bool = false      //주차장 진입로
  
  //Array List
  var stopList = [Int]()
  
  var beaconEndMajor: Int = 0
  
  //생성자들
  let b : Beacon = Beacon()
  let s : Sensor = Sensor()
  let g : Gyro = Gyro()
  let acb : AccelBeacon = AccelBeacon()
  let acbc : AccelBeaconChange = AccelBeaconChange()
  let accelDataC : AccelData = AccelData()
  let network :DataNetworkInfo = DataNetworkInfo()
  let queue = QueueData()
  let Accel = AccelResultData()
  
  let exceptionData : ExceptionData = ExceptionData.instance
  
  //Sensor data 수집하는데 나중에 서버로 보내는 작업을 할 때 어떤 사용자가 사용했는지 식별하기 위해서 전화번호가 필요함
  var collectSensor = CollectSensor(phoneInfo: "")
  
  //KalmanFilter 자동차 움직임을 측정하기 위한 필터
  var KalRoll = KalFilter()
  var KalPitch = KalFilter()
  var KalYaw = KalFilter()
  
  //Queue 생성자 (Accel queue 초기화)
  var RollQ = QueueData.Queue<Double>()
  var PitchQ = QueueData.Queue<Double>()
  var YawQ = QueueData.Queue<Double>()
  
  var StopQ = QueueData.Queue<Int>()
  var AccelQ = QueueData.Queue<String>()
  
  //단일 UUID 사용시
  let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: "20151005-8864-5654-3020-013900202001")!, identifier: "MyBecon")
  
  //다중 UUID 사용시
  //    let beaconRegions = [CLBeaconRegion(proximityUUID: UUID(uuidString: "20151005-8864-5654-4159-013500201901")! as UUID, identifier: "MyBecon"),
  //                         CLBeaconRegion(proximityUUID: UUID(uuidString: "20151005-8864-5654-4159-013500201902")! as UUID, identifier: "MyBecon2"),
  //                         CLBeaconRegion(proximityUUID: UUID(uuidString: "20151005-8864-5654-3020-013900202003")! as UUID, identifier: "MyBecon3"),
  //    ]
  override init() {
    super.init()
    locationManager = CLLocationManager.init()                  //locatioManager 초기화.
    locationManager.delegate = self                             // delegate 넣어줌
    locationManager.requestAlwaysAuthorization()                // 위치 권한 받아옴.
    
    locationManager.allowsBackgroundLocationUpdates = true      // 백그라운드에서 위치를 체크할 것인지에 대한 여부. 필요없으면 false
    locationManager.pausesLocationUpdatesAutomatically = false  // 이걸 false 써줘야 백그라운드에서 멈추지 않고 돈다.
    locationManager.stopUpdatingLocation()
    locationManager.startUpdatingLocation()                     // 위치 업데이트 시작
    locationManager.startMonitoringSignificantLocationChanges()
    
    lobbyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(lobbyTimerFunction), userInfo: nil, repeats: true)
  }
}

// MARK: - Life Cycle
extension BeaconService {
  @objc(beaconServiceStart:)
  func beaconServiceStart(_ cel: String) {
    CollectSensor.init(phoneInfo: cel)
    locationManager.startRangingBeacons(in: beaconRegion)
    print("SmartParking START")
  }
  
  @objc
  func beaconServiceStop() {
    locationManager.stopRangingBeacons(in: beaconRegion)
    resetData()
    resetTimer()
    print("SmartParking STOP")
  }
}

extension BeaconService {
  @objc func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion){
    
    //Time Data =====================================================
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    for i in 0 ..< beacons.count
    {
      //Beacon Data =====================================================
      let major = Int(truncating: beacons[i].major)
      let minor = Int(truncating: beacons[i].minor)
      let rssi = beacons[i].rssi
      
      func startSecond(){
        beaconMajor1 = false
        beaconMajor3 = false
        
        counterFlag = true
        
        motion.stopGyroUpdates()
        motion.stopAccelerometerUpdates()
        
        timer.invalidate()
        accelTimer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFunction), userInfo: nil, repeats: true)
        accelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(accelTimerFunction), userInfo: nil, repeats: true)
        
        print("App Start 주차 시스템 시작")
      }
      func appFuntionAccle(){
        if AccelBeaconPermission == true
        {
          if minor > 32768
          {
            ModifiMinor = minor - 32768
          }
          else
          {
            ModifiMinor = minor
          }
          
          //hex 바꿀수 있는 데이터 형식으로 변환
          var hexString = String(format: "%02X", ModifiMinor)
          
          if hexString.count < 4 {
            
            for _ in 0..<4 - hexString.count {
              let zeroString = "0"
              
              hexString = zeroString + hexString
            }
          }
          
          if acb.AccelBeaconDic[("\(hexString)")] == nil {
            let accelData = AccelData()
            accelData.id = ("\(hexString)")
            accelData.rssi = ("\(rssi)")
            accelData.delay = ("\(counter)")
            accelData.count = "1"
            
            acb.AccelBeaconDic[("\(hexString)")] = accelData
          }
          else{
            var accelData = AccelData()
            
            accelData = acb.AccelBeaconDic[("\(hexString)")] as! AccelData
            
            let value : Int =  Int(accelData.count)! + 1
            
            if Int(accelData.rssi)! > beacons[i].rssi {
              
              let accelData2 = AccelData()
              accelData2.id = accelData.id
              accelData2.rssi = accelData.rssi
              accelData2.delay = accelData.delay
              accelData2.count = ("\(value)")
              
              acb.AccelBeaconDic.updateValue(accelData2, forKey: ("\(hexString)"))
            }
            else{
              let accelData2=AccelData()
              accelData2.id = ("\(hexString)")
              accelData2.rssi = ("\(beacons[i].rssi)")
              accelData2.delay = ("\(counter)")
              accelData2.count = ("\(value)")
              
              acb.AccelBeaconDic.updateValue(accelData2, forKey: ("\(hexString)"))
            }
          }
        }
      }
      func appFuntionBeacon(){
        
        //주차가 된 상태(초록불 -> 빨간불)
        if minor > 32768
        {
          ModifiMinor = minor - 32768
          
          //hex 바꿀수 있는 데이터 형식으로 변환
          var hexString = String(format: "%02X", ModifiMinor)
          
          if hexString.count < 4 {
            
            for _ in 0..<4 - hexString.count {
              let zeroString = "0"
              
              hexString = zeroString + hexString
            }
          }
          
          BeaconSeq += 1
          
          b.addBeaconDic(seq: "\(BeaconSeq)", id: "\(hexString)", state: "\(major)", rssi: "\(rssi)", delay: "\(counter)")
          collectSensor.addBeacon(b: b)
        }
        
      }
      func appOutSide(){
        
        resetData()
        
        let url = URL(string: "http://\(network.IP):" + "\(network.PORT)/" + "pms" + "\(network.realServer)" + "web/app/outParking?userId=" + "\(DataLoginReturn.instance.id)&" + "dong=" + "\(DataLoginReturn.instance.dong)&" + "ho=" + "\(DataLoginReturn.instance.ho)")!
        
        if NetworkCheck.isConnectedToNetwork() == true {
          
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          request.addValue("application/json", forHTTPHeaderField: "Accept")
          
          let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
              print(error?.localizedDescription ?? "No data")
              
              print("서버 점검중입니다.")
              
              return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
              DispatchQueue.main.async {
                let results = responseJSON
                print("밖으로 나감 : \(results)")
              }
            }
          }
          task.resume()
          
        }
        else if NetworkCheck.isConnectedToNetwork() == false {
          print("인터넷 연결에 실패하였습니다.")
        }
      }
      func startInfo(){
        // create post request 서버로 보내는 작업
        let url = URL(string: "http://\(network.IP):\(network.PORT)/pms\(network.realServer)web/app/gateInfo?userId=\(DataLoginReturn.instance.id)&major=\(major)&minor=\(minor)")!    //LTE
        
        if NetworkCheck.isConnectedToNetwork() == true
        {
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          
          let boundaryConstant = generateBoundary()
          
          request.addValue("multipart/form-data; boundary=\(boundaryConstant)", forHTTPHeaderField: "Content-Type")
          
          let parameters = ["userId": "\(DataLoginReturn.instance.id)", "major": "\(major)", "minor":"\(minor)"]
          
          let dataBody = createDataBody(withParameters: parameters, boundary: boundaryConstant)
          
          request.httpBody = dataBody
          
          let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
              print(error?.localizedDescription ?? "No data")
              return
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if (responseJSON as? [String: Any]) != nil {
              DispatchQueue.main.async {
                
                print("시작 \(major) 정보 보냄")
              }
            }
          }
          task.resume()
        }
        else if NetworkCheck.isConnectedToNetwork() == false {
          print("인터넷 연결에 실패하였습니다.")
        }
      }
      
      let stringDate = dateFormatter.string(from: date)
//      print("Time : \(stringDate)")
      
      switch major {
      case 1:
        if rssi != 0{
          print("Major : \(major)")
          
//          //hex 바꿀수 있는 데이터 형식으로 변환
//          var hexLobby: String? = String(format: "%02X", minor)
//          if (hexLobby != nil) {
//            if hexLobby!.count < 4 {
//              for _ in 0..<4 - hexLobby!.count {
//                let zeroString = "0"
//
//                hexLobby = zeroString + hexLobby!
//              }
//            }
//          }
//
//          let thirdIndex = hexLobby?.index(hexLobby!.startIndex, offsetBy: 2)
//          let outsideLobby = hexLobby![thirdIndex!]
          
          if endBeaconTimerCheck == true {
            stopList.append(major)
          }
          
          if counterFlag == true {
            print("전체 타이머 상태 1 : \(counterFlag) | \(stringDate)")
            if beaconMajor1 == false && beaconMajor3 == false {
              
              startInfo()
              
              print("일반주차 완료 1 majorNumber : \(major) / beacon권한 beaconMajor1 = \(beaconMajor1) : beaconMajor3 = \(beaconMajor3)")
              
              beaconMajor1 = true
            }
          }
          if counterFlag == false {
            print("전체 타이머 상태 2 : \(counterFlag) | \(stringDate)")
            if beaconMajor1 == false && beaconMajor3 == true {
              
              startInfo()
              
              
              print("이동주차 시작 2 Beacon : \(major) / 권한 beaconMajor1 = \(beaconMajor1) : beaconMajor3 = \(beaconMajor3)")
              
              beaconMajor1 = true
              beaconMajor3 = false
              startBeaconTimerCheck = true
              
              collectSensor.inputDate = "move"
              collectSensor.paringDate = "non-paring"     // Android에서 Paring 상태에선 비컨을 잘 못받기 때문에 상태 확인하는 것인데 IOS에서는 사용 안해서 [non]으로 고정시켜서 보냄
              
              collectSensor.addStartTime()
              collectSensor.addParingState()
              
              startBeaconTimer.invalidate()
              
              AccelStart()
              GyroStart()
              
              accelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(accelTimerFunction), userInfo: nil, repeats: true)
              startBeaconTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startCheckFunction), userInfo: nil, repeats: true)
            }
          }
        }
        break
      case 2:
        if rssi != 0 {
          print("Major : \(major)")
          if beaconMajor2 == false && beaconMajor6 == false {
            startInfo()
            beaconMajor2 = true
          }
          if beaconMajor2 == false && beaconMajor6 == true {
            startInfo()
            beaconMajor2 = true
            appOutSide()
          }
        }
        break
      case 3:
        if rssi != 0 {
          print("Major : \(major)")
          if endBeaconTimerCheck == true {
            stopList.append(major)
          }
          
          StopQ.push(value: major)
          
          if counterFlag == true {
            print("전체 타이머 상태 3 : \(counterFlag)")
            if beaconMajor1 == true && beaconMajor3 == false {
              
              print("일반주차 완료 2 Beacon : \(major) / 권한 beaconMajor1 = \(beaconMajor1) : beaconMajor3 = \(beaconMajor3)")
              
              startInfo()
              
              beaconMajor3 = true
              endBeaconTimerCheck = true
              endBeaconTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(endCheckFunction), userInfo: nil, repeats: true)
            }
          }
          
          if counterFlag == false {
            print("전체 타이머 상태 : \(counterFlag)")
            if beaconMajor1 == false && beaconMajor3 == false {
              
              print("이동주차 시작 1 Beacon : \(major) / 권한 beaconMajor1 = \(beaconMajor1) : beaconMajor3 = \(beaconMajor3)")
              
              startInfo()
              
              //시작전 타이머 종료(다시 시작 할꺼라)
              accelTimer.invalidate()
              
              motion.stopGyroUpdates()
              motion.stopAccelerometerUpdates()
              
              beaconMajor3 = true
            }
          }
        }
        break
      case 4:
        if rssi != 0 {
          print("Major : \(major)")
          appFuntionAccle()
        }
        break
      case 5:
        if rssi != 0 {
          print("Major : \(major)")
          appFuntionAccle()
          appFuntionBeacon()
        }
        break
      case 6:
        if rssi != 0 {
          print("Major : \(major)")
          if beaconMajor2 == true && beaconMajor6 == false {
            startInfo()
            beaconMajor6 = true
            
            let stringDate = dateFormatter.string(from: date)
            collectSensor.inputDate = stringDate
            collectSensor.paringDate = "non-paring"         // Android에서 Paring 상태에선 비컨을 잘 못받기 때문에 상태 확인하는 것인데 IOS에서는 사용 안해서 [non]으로 고정시켜서 보냄.
            
            collectSensor.addStartTime()
            collectSensor.addParingState()
            
            startSecond()
          }
          else if beaconMajor2 == false && beaconMajor6 == false {
            startInfo()
            beaconMajor6 = true
          }
        }
        break
      default:
        break
      }
    }
  }
  
  //form-data 만드는데 필요
  func generateBoundary() -> String {
    return "Boundary-\(UUID().uuidString)"
  }
  //form-data 만드는데 필요
  func createDataBody(withParameters params: Parameters?, boundary: String) -> Data {
    
    let lineBreak = "\r\n"
    var body = Data()
    
    if let parameters = params {
      for (key, value) in parameters {
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
        body.append("\(value + lineBreak)")
      }
    }
    body.append("--\(boundary)--\(lineBreak)")
    
    return body
  }
  
  //종료와 함께 초기화 되는 함수들
  func resetData() {
    counter = 0
    SensorSeq = 0
    BeaconSeq = 0
    
    //Gyro data 초기화
    PreRollCount = 0
    PrePitchCount = 0
    PreYawCount = 0
    RollResultCount = 0
    PitchResultCount = 0
    YawResultCount = 0
    
    //Accel data 초기화
    PreValue = 0
    NextValue = 0
    ResultCount = 0
    
    b.addBeaconDic(seq: "", id: "", state: "", rssi: "", delay: "")
    s.addSensorDic(seq: "", state: "", delay: "")
    g.addGyroDic(x: "", y: "", z: "", delay: "")
    acbc.addAccelBeaconChangeDic(id: "", rssi: "", delay: "", count: "")
    
    //Dictionay 전부 초기화
    collectSensor.removeData()
    
    counterFlag = false
    sensorFlag = false
    AccelBeaconPermission = false
    
    beaconMajor1 = false
    beaconMajor3 = false
    beaconMajor2 = false
    beaconMajor6 = false
    
    //Timer 종료
    timer.invalidate()
  }
  
  func resetTimer() {
    timer.invalidate()
    lobbyTimer.invalidate()
    endBeaconTimer.invalidate()
    startBeaconTimer.invalidate()
    accelTimer.invalidate()
  }
}

extension BeaconService {
  // 새로 비컨 수집 기능 수정중 0911================================================================================
  
  func initializeLocationManager() {
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    locationManager.startUpdatingLocation()
    locationManager.allowsBackgroundLocationUpdates = true
  }
  
  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    if state == .inside {
      locationManager.startRangingBeacons(in: self.beaconRegion)
      print("검색 시작 0")
    } else if state == .outside {
      locationManager.stopRangingBeacons(in: self.beaconRegion)
      print("검색 중지 0")
    } else if state == .unknown {
      print("Now unknown of Region")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("비콘이 범위 내에 있음")
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    print("비콘이 범위 밖을 벗어남")
  }
  
  func startRanging() {
    
    if exceptionData.startLimit == 0 {
      
      exceptionData.startLimit = 1
      
      locationManager.startRangingBeacons(in: self.beaconRegion)
      print("검색 시작 1")
    }
    
  }
  
  func stopRanging() {
    locationManager.stopRangingBeacons(in: self.beaconRegion)
    print("검색 중지 1")
  }
  
  //==========================================================================================================
  @objc func timerFunction() {
    if counterFlag == true
    {
      if sensorFlag == false {
        sensorFlag = true
        //자이로, 엑셀이 센서가 동작함
        print("timer Start")
        
        AccelStart()
        GyroStart()
      }
      
      //Timer count 증가
      counter += 1
      
      //15분이 지나면 Beacon기능 제외 모든기능 정지 후 서버로 데이터 보냄
      if counter == 900
      {
        let stringDate = dateFormatter.string(from: date)
        
        parkingTime = stringDate
        
        let d =  collectSensor.collectDataDic
        
        //수집한 데이터들
        let jsonData = try? JSONSerialization.data(withJSONObject: d as AnyObject, options: [])
        
        // create post request 서버로 보내는 작업
        let url = URL(string: "http://\(network.IP):\(network.PORT)pms\(network.realServer)web/app/calcLocation?userId=\(DataLoginReturn.instance.id)&dong=\(DataLoginReturn.instance._dong)&ho=\(DataLoginReturn.instance.ho)")!     //LTE
        
        if NetworkCheck.isConnectedToNetwork() == true
        {
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          request.addValue("application/json", forHTTPHeaderField: "Accept")
          
          // insert json data to the request
          request.httpBody = jsonData
          
          let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
              print(error?.localizedDescription ?? "No data")
              
              self.sendDataPermission = false
              
              //                            //create the alert
              //                            let alert = UIAlertController(title: "서버와의 접속이 원활하지 않습니다.", message: "The server is in bad shape.", preferredStyle: UIAlertController.Style.alert)
              //                            //add an action (Button)
              //                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
              //
              //                            // show the alert
              //                            self.present(alert, animated: true, completion: nil)
              return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
              DispatchQueue.main.async {
                print(responseJSON)
                
                //Beacon Permission 제거(이동주차)
                self.beaconMajor1 = false
                self.sendDataPermission = false
              }
            }
          }
          task.resume()
          resetData()
        }
          
        else if NetworkCheck.isConnectedToNetwork() == false
        {
          if networkPerMission == false
          {
            networkPerMission = true
            while true
            {
              if NetworkCheck.isConnectedToNetwork() == true
              {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                // insert json data to the request
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                  guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    
                    self.sendDataPermission = false
                    
                    //                                        //create the alert
                    //                                        let alert = UIAlertController(title: "서버와의 접속이 원활하지 않습니다.", message: "The server is in bad shape.", preferredStyle: UIAlertController.Style.alert)
                    //                                        //add an action (Button)
                    //                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    //
                    //                                        // show the alert
                    //                                        self.present(alert, animated: true, completion: nil)
                    return
                  }
                  let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                  if let responseJSON = responseJSON as? [String: Any] {
                    DispatchQueue.main.async {
                      print(responseJSON)
                      //Beacon Permission 제거(이동주차)
                      self.beaconMajor1 = false
                      self.sendDataPermission = false
                    }
                  }
                }
                task.resume()
                resetData()
                break
              }
            }
          }
        }
      }
    }
  }
  
  @objc func accelTimerFunction(){
    accelCount += 1
    
    //2초마다 데이터 수집
    acceleDivision = accelCount % 2
    
    if acceleDivision == 0 {
      
      //SensorSeq 증가
      SensorSeq += 1
      
      if ResultCount < 3 && ResultCount >= 0
      {
        Result = "T"
      }
      else if ResultCount < 12 && ResultCount >= 3
      {
        Result = "S"
      }
      else
      {
        Result = "W"
      }
      //이동주차 시작할 때 필요한 상태값 얻기
      AccelResultData.instance.accRsult = Result
      //주차완료 할때 필요한 Queue저장 차에서 처음 내릴때 알기
      if AccelQ.count == 0 {
        AccelQ.push(value: Result)
      } else {
        AccelQ.push(value: Result)
        
        let firstResult: String = AccelQ.pop()
        let scondResult: String = AccelQ.pop()
        
        if firstResult == "T" && (scondResult == "S" || scondResult == "W") {
          AccelBeaconPermission = true
        }
        AccelQ.push(value: scondResult)
      }
      
      if AccelBeaconPermission == true {
        AccelBeaconGet += 1
        
        if AccelBeaconGet == 3 {
          
          AccelBeaconGet = 0
          AccelBeaconPermission = false
        }
      }
      
      if counterFlag == true {
        s.addSensorDic(seq: "\(SensorSeq)", state: "\(Result)", delay: "\(counter)")
        collectSensor.addSensor(s: s)
      }
      
      accel_count = 0
      ResultCount = 0
    }
  }
  
  @objc func lobbyTimerFunction(){
    if lobbyStart == true {
      
      lobbyCount += 1
      
      if lobbyCount == 2 {
        
        lobbyCount = 0
        lobbyStart = false
      }
    }
  }
  
  @objc func endCheckFunction() {
    if endBeaconTimer.isValid == true {
      endCheckCount += 1
      
      if endCheckCount == 2 {
        endCheckCount = 0
        
        endBeaconTimer.invalidate()
        
        print("stopList 갯수 : \(stopList.count)")
        
        if stopList.count != 0 {
          
          beaconEndMajor = stopList.last!
          print("마지막 stopList: \(beaconEndMajor)")
          
          stopList.removeAll()
          //                    stopList.remove(at: stopList.last!)
          
          endBeaconTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(endCheckFunction), userInfo: nil, repeats: true)
          
        } else {
          if beaconEndMajor == 3 {
            print("Beacon 종료")
            endBeaconTimer.invalidate()
            stopSecond()
          } else if beaconEndMajor == 1 {
            endBeaconTimer.invalidate()
            print("종료 안하고 다시 로비로 나옴")
            beaconMajor1 = false
            beaconMajor3 = false
          }
        }
      }
    }
  }
  
  @objc func startCheckFunction() {
    if startBeaconTimerCheck == true {
      startCheckCount += 1
      
      print("startCheckCount : \(startCheckCount)")
      
      if startCheckCount == 900 {
        //다되면 타이머를 멈춰야 할까??
        resetData()
        
        accelTimer.invalidate()
        startBeaconTimer.invalidate()
        
        beaconMajor1 = false
        beaconMajor3 = false
      }
    }
  }
  
  func stopSecond() {
    
    print("종료 후 서버 날림")
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    
    for accelB in acb.AccelBeaconDic
    {
      var accelDataSend : AccelData = AccelData()
      
      accelDataSend = accelB.value as! AccelData
      
      acbc.addAccelBeaconChangeDic(id: accelDataSend.id, rssi: accelDataSend.rssi, delay: accelDataSend.delay, count: accelDataSend.count )
      collectSensor.addAccelBeacon(abcb: acbc)
    }
    
    //수집한 데이터들
    let jsonData = try? JSONSerialization.data(withJSONObject: collectSensor.collectDataDic as AnyObject, options: [])
    
    print("수집 데이터 : \(collectSensor.collectDataDic)")
    
    // create post request 서버로 보내는 작업
    let url = URL(string: "http://\(network.IP):" + "\(network.PORT)/" + "pms" + "\(network.realServer)" + "web/app/calcLocation?userId=" + "\(DataLoginReturn.instance.id)&" + "dong=" + "\(DataLoginReturn.instance.dong)&" + "ho=" + "\(DataLoginReturn.instance.ho)")!    //LTE
    
    print("전체 타이머 : \(counter)")
    
    if counter >= 10 {
      
      if NetworkCheck.isConnectedToNetwork() == true {
        print("인터넷 연결 된 상태")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            
            self.sendDataPermission = false
            return
          }
          let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
          if let responseJSON = responseJSON as? [String: Any] {
            DispatchQueue.main.async {
              print(responseJSON)
              
              //Beacon Permission 제거(이동주차)
              self.beaconMajor1 = false
              self.sendDataPermission = false
            }
          }
        }
        task.resume()
        resetData()
      }
      else if NetworkCheck.isConnectedToNetwork() == false {
        print("인터넷 연결 안된 상태")
        
        if networkPerMission == false
        {
          networkPerMission = true
          while true
          {
            if NetworkCheck.isConnectedToNetwork() == true
            {
              var request = URLRequest(url: url)
              request.httpMethod = "POST"
              
              request.addValue("application/json", forHTTPHeaderField: "Content-Type")
              request.addValue("application/json", forHTTPHeaderField: "Accept")
              
              // insert json data to the request
              request.httpBody = jsonData
              
              let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                  print(error?.localizedDescription ?? "No data")
                  
                  self.sendDataPermission = false
                  return
                }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                  DispatchQueue.main.async {
                    print(responseJSON)
                    //Beacon Permission 제거(이동주차)
                    self.beaconMajor1 = false
                    self.sendDataPermission = false
                  }
                }
              }
              task.resume()
              break
            }
          }
        }
        resetData()
      }
    }
  }
}

extension BeaconService {
  @objc func AccelStart() {
    print("ACCEL START")
    // Make sure the accelerometer hardware is available.
    if self.motion.isAccelerometerAvailable {
      self.motion.accelerometerUpdateInterval = 1.0 / 15.0  // 초당 15회 발생
      self.motion.startAccelerometerUpdates()
      
      // 데이터로 무언가 수행하도록 타이머 구성
      self.timer = Timer(fire: Date(), interval: (1.0/15.0),
                         repeats: true, block: { (timer) in
                          // Get the accelerometer data.
                          if let data = self.motion.accelerometerData {
                            
                            self.data_x = data.acceleration.x
                            self.data_y = data.acceleration.y
                            self.data_z = data.acceleration.z
                            
                            self.AccelerimerResult()
                          }
      })
      // Add the timer to the current run loop.
      RunLoop.current.add(self.timer, forMode: RunLoop.Mode.default)
    }
  }
}

extension BeaconService {
  @objc func AccelerimerResult() {
    
    CVA = sqrt(data_x * data_x + data_y * data_y + data_z * data_z)
    
    if(PreValue != 0){
      NextValue = CVA
      
      let ABSValue: Double = abs(PreValue - NextValue)
      
      if ABSValue >= DefaltAbsValue {
        accel_count += 1
      }
      PreValue = NextValue
      ResultCount = accel_count
    }
    else
    {
      PreValue = CVA
    }
  }
}

extension BeaconService {
  @objc func GyroStart() {
    print("GYRO START")
    if motion.isGyroAvailable {
      self.motion.gyroUpdateInterval = 1.0/6.0
      self.motion.startGyroUpdates()
      
      //Configure a timer to fetch the accelerometer data.
      self.timer = Timer(fire: Date(), interval: (1.0/6.0),
                         repeats: true, block: {(timer) in
                          if let data = self.motion.gyroData {
                            self.data_roll = data.rotationRate.x
                            self.data_pitch = data.rotationRate.y
                            self.data_yaw = data.rotationRate.z
                            
                            if ((self.data_roll > self.LIMIT_MAX || self.data_roll < self.LIMIT_MIN)
                              || (self.data_pitch > self.LIMIT_MAX || self.data_pitch < self.LIMIT_MIN)
                              || (self.data_yaw > self.LIMIT_MAX || self.data_yaw < self.LIMIT_MIN))
                            {
                              self.useFlag = false;
                            }
                            if self.useFlag == false
                            {
                              self.KalRoll.initFilter()
                              self.KalPitch.initFilter()
                              self.KalYaw.initFilter()
                            } else {
                              self.kal_Roll = self.KalRoll.Update(Value: self.data_roll)
                              self.kal_Pitch = self.KalPitch.Update(Value: self.data_pitch)
                              self.kal_Yaw = self.KalYaw.Update(Value: self.data_yaw)
                            }
                            self.GyroSensorResult()
                          }
      })
      RunLoop.current.add(self.timer, forMode: RunLoop.Mode.default)
    }
  }
}

extension BeaconService {
  @objc func GyroSensorResult() {
    //var countG :Int += 1
    //        let MaxValue: Double = 0.5
    //        let MinValue: Double = -0.5
    
    let LimitPlus: Double = 0.035
    let LimitMinus: Double = -0.035
    
    if RollQ.count == 4
    {
      if (!((RollQ.elements[0]<LimitPlus && RollQ.elements[0]>LimitMinus) || (RollQ.elements[1]<LimitPlus && RollQ.elements[1]>LimitMinus) || (RollQ.elements[2]<LimitPlus && RollQ.elements[2]>LimitMinus) || (RollQ.elements[3]<LimitPlus && RollQ.elements[3]>LimitMinus)))
      {
        if(self.useFlag)
        {
          RollResultCount += 1
        }
      }
      else
      {
        PreRollCount = RollResultCount
        
        RollResultCount = 0
      }
      var _ : Double = RollQ.pop()
      let SECONDR : Double = RollQ.pop()
      let THIRDR : Double = RollQ.pop()
      let FORTHR : Double = RollQ.pop()
      
      RollQ.push(value: SECONDR)
      RollQ.push(value: THIRDR)
      RollQ.push(value: FORTHR)
      RollQ.push(value: kal_Roll)
    }
    else
    {
      RollQ.push(value: kal_Roll)
    }
    
    if PitchQ.count == 4
    {
      if (!((PitchQ.elements[0]<LimitPlus && PitchQ.elements[0]>LimitMinus) || (PitchQ.elements[1]<LimitPlus && PitchQ.elements[1]>LimitMinus) || (PitchQ.elements[2]<LimitPlus && PitchQ.elements[2]>LimitMinus) || (PitchQ.elements[3]<LimitPlus && PitchQ.elements[3]>LimitMinus)))
      {
        if(self.useFlag)
        {
          PitchResultCount += 1
        }
      }
      else
      {
        PrePitchCount = PitchResultCount
        PitchResultCount = 0
      }
      
      var _ : Double = PitchQ.pop()
      let SECONDR : Double = PitchQ.pop()
      let THIRDR : Double = PitchQ.pop()
      let FORTHR : Double = PitchQ.pop()
      
      PitchQ.push(value: SECONDR)
      PitchQ.push(value: THIRDR)
      PitchQ.push(value: FORTHR)
      PitchQ.push(value: kal_Pitch)
    }
    else
    {
      PitchQ.push(value: kal_Pitch)
    }
    
    if YawQ.count == 4
    {
      if (!((YawQ.elements[0]<LimitPlus && YawQ.elements[0]>LimitMinus) || (YawQ.elements[1]<LimitPlus && YawQ.elements[1]>LimitMinus) || (YawQ.elements[2]<LimitPlus && YawQ.elements[2]>LimitMinus) || (YawQ.elements[3]<LimitPlus && YawQ.elements[3]>LimitMinus)))
      {
        if(self.useFlag)
        {
          YawResultCount += 1
        }
      }
      else
      {
        PreYawCount = YawResultCount
        YawResultCount = 0
      }
      
      var _ : Double = YawQ.pop()
      let SECONDR : Double = YawQ.pop()
      let THIRDR : Double = YawQ.pop()
      let FORTHR : Double = YawQ.pop()
      
      YawQ.push(value: SECONDR)
      YawQ.push(value: THIRDR)
      YawQ.push(value: FORTHR)
      YawQ.push(value: kal_Yaw)
    }
    else
    {
      YawQ.push(value: kal_Yaw)
    }
    if PreRollCount >= 7 || PrePitchCount >= 7 || PreYawCount >= 7
    {
      gyrosavecount += 1
      gyroSaveFlag = true
      
      if counterFlag == true && startBeaconTimerCheck == false {
        print("gyro Add")
        g.addGyroDic(x: "\(PreRollCount)", y: "\(PrePitchCount)", z: "\(PreYawCount)", delay: "\(counter)")
      }
      
      print("Result : \(AccelResultData.instance.accRsult)")
      if startBeaconTimerCheck == true {
        
        if AccelResultData.instance.accRsult == "T" {
          
          startBeaconTimerCheck = false
          startBeaconTimer.invalidate()
          startCheckCount = 0
          
          startSecond()
        }
      }
      
      print("GyroDictionay : \(collectSensor.gyros)")
      
      PreRollCount = 0
      PrePitchCount = 0
      PreYawCount = 0
    }
    else
    {
      gyroSaveFlag = false
      if gyroSaveFlag == false && gyrosavecount != 0 && counterFlag == true
      {
        if g.GyroDic.count != 0 {
          collectSensor.addGyro(g: g)
        }
        
        gycount += 1
        
        //자이로 카운터가 2개 이상 일어날시 이전 일반 비컨값 제거
        if gycount == 2 {
          collectSensor.removeAccelBeacon()
          gycount = 0
        }
        gyroSaveFlag = false
        gyrosavecount = 0
      }
    }
    if(self.useFlag == false)
    {
      PreRollCount = 0
      PrePitchCount = 0
      PreYawCount = 0
    }
    self.useFlag = true
  }
  
  func startSecond(){

    counterFlag = true

    beaconMajor1 = false
    beaconMajor3 = false

    timer.invalidate()

    motion.stopGyroUpdates()
    motion.stopAccelerometerUpdates()

    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFunction), userInfo: nil, repeats: true)

    print("App Start 이동 주차 시스템 시작 !!")
  }
}

