# Smart UV Checker BT

## 0. 목차
[1. 소개](#1-소개)<br>
[2. 화면 흐름도](#2-화면-흐름도)<br>
[3. 기능 소개](#3-기능-소개)<br>
[4. 개발 환경](#4-개발-환경)<br>

## 1. 소개
구글 플레이스토어에서 다운 받기 👉 https://play.google.com/store/apps/details?id=com.geniuv.smartuvcheckerbt

- 개요 : Bluetooth로 자외선 센서 장치와 연동해 자외선 INTENSITY, DOSE, INDEX, UVC SAFE 측정값을 그래프 혹은 수치로 출력해주는 모바일 어플리케이션
- 담당 업무 : 모바일 앱 개발
- 개발 기간 : 2020.03.23 ~ 2020.07.01
- 근무처 : 테크노니아, Genicom

<br/>

## 2. 화면 흐름도
<img src="https://user-images.githubusercontent.com/62532878/136946135-3e9c3acd-510d-4344-b060-ac138aab2027.PNG" alt="화면흐름도" weight="800"/>

## 3. 기능 소개
### 1️⃣ 초기 화면
<img src="https://user-images.githubusercontent.com/62532878/136947523-cad7311f-79c7-4332-9f4d-e015bef9d0b5.png" alt="초기화면" height="600"/>
<br>

> 돋보기 버튼을 통해 블루투스 스캔을 시작할 수 있습니다.

<br>

### 2️⃣ 블루투스 스캔
<img src="https://user-images.githubusercontent.com/62532878/136947989-56edc477-a9d1-45d2-bb6d-ef668ad0b447.png" alt="블루투스스캔" height="600"/>
<br>

> 중지 버튼을 통해 블루투스 스캔을 중지하고, 스캔된 목록에서 UV 측정 기기를 선택해 연결할 수 있습니다.

<br>

### 3️⃣ 메인 화면
3-1. 메인<br>
3-2. 블루투스 미연결시 경고<br>
3-3. UV 측정기기에서의 올바르지 않은 스위치값 입력시<br>
3-4. 스위치값 리스트<br>
<div float="left">
<img src="https://user-images.githubusercontent.com/62532878/136947994-ff40fc59-48d6-4f73-9a99-a211b62a40fb.png" alt="메인화면" height="600"/>
<img src="https://user-images.githubusercontent.com/62532878/136947997-4e13fca0-130f-4528-81ba-058b372e7b2e.png" alt="블루투스미연결시" height="600"/>
<img src="https://user-images.githubusercontent.com/62532878/136947998-f3a0cde7-30ce-48a6-874b-1062d632e727.png" alt="메인화면" height="600"/>
</div>
<div float="left">
<img src="https://user-images.githubusercontent.com/62532878/136948000-c9788181-ba24-46c6-81da-fafed4254038.PNG" alt="블루투스미연결시" height="300"/>
</div>

<br>

> 블루투스 연결이 완료되지 않은 상태에서 메인화면 로드시 'not connected yet' 경고창이 뜹니다.
>  UV 측정 기기의 스위치값이 조회 가능하지 않을시 '스위치 Setting을 확인해주세요.' 경고창이 뜨게 됩니다.

<br>

### 4️⃣ UV Intensity
<div float="left">
<img src="https://user-images.githubusercontent.com/62532878/136948001-065cb293-e4fc-48eb-a2b1-a9769d0a588d.png" alt="메인화면" height="600"/>
<img src="https://user-images.githubusercontent.com/62532878/136948003-827bdc2b-e34a-45e5-9716-774d71a627b7.png" alt="블루투스미연결시" height="600"/>
</div>
<br>

> START/STOP 버튼으로 측정을 시작하거나 중지하고, 측정되는 UV값의 최소값, 최소값, 평균값을 보여줍니다. 캡처하거나 xml 파일로 저장할 수 있습니다.

- MIN : 측정된 UV값 중 최소값
- MAX : 측정된 UV값 중 최대값
- AVG : 측정된 UV값의 평균값

<br>

### 5️⃣ UV Dose
<div float="left">
<img src="https://user-images.githubusercontent.com/62532878/136948007-bccce40c-e55b-46db-a507-1c8e75c8ce63.png" alt="메인화면" height="600"/>
<img src="https://user-images.githubusercontent.com/62532878/136948010-717e60d6-2713-4787-b338-f2948868d719.png" alt="블루투스미연결시" height="600"/>
</div>
<br>

> START/STOP 버튼으로 측정을 시작하거나 중지하고, 측정되는 UV값을 유동 그래프로 보여줍니다.

- UV Power : 실시간 UV 측정값
- Start ~ End Time : 측정 시작 ~ 측정 끝 시간
- Accumulated Time : 누적 측정 시간
- Dose : 누적 UV 값
<br>

### 6️⃣ UV Index
<div float="left">
<img src="https://user-images.githubusercontent.com/62532878/136948016-708b0a09-75d0-4dc1-b209-c357ca3afbf8.png" alt="메인화면" height="600"/>
<img src="https://user-images.githubusercontent.com/62532878/136948017-510b8591-df7a-4aef-9382-b533dbf3c947.png" alt="블루투스미연결시" height="600"/>
</div>
<br>

> 측정된 UV값에 따른 경고문과 필요한 보호구를 나타냅니다.

<br>

### 7️⃣ UVC Safe
<div float="left">
<img src="https://user-images.githubusercontent.com/62532878/136948020-ecc5d2d4-0adb-47a6-8f87-e325aa3154a4.png" alt="메인화면" height="600"/>
<img src="https://user-images.githubusercontent.com/62532878/136948022-df9fa8d3-1c2e-4631-bcd6-9585f89a88db.png" alt="블루투스미연결시" height="600"/>
</div>

<br>

> 측정된 UV값에 노출시 인체에 영향을 미치는 범위를 계산하고 허용 가능한 시간을 나타냅니다.

- Irradiation : 측정값
- Biological effective Irradiation : 해당 측정값이 인체에 영향을 미치는 범위를 계산한 값

<br>

## 4. 개발 환경
### 🛠 개발 도구 : <img src="https://img.shields.io/badge/Flutter-blue?style=flat-square&logo=Flutter&logoColor=white" height="30"/> <img src="https://img.shields.io/badge/Dart-1572B6?style=flat-square&logo=Dart&logoColor=white" height="30"/> <img src="https://img.shields.io/badge/Android Studio-269539?style=flat-square&logo=AndroidStudio&logoColor=white" height="30"/>
### :iphone: Target Device : LM G710VM
### 🧾 Target SDK Version : 28
