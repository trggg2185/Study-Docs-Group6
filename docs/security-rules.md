# Hướng dẫn Security Rules cho StudyDocs

## 1. Mục tiêu

Security Rules là cơ chế kiểm soát quyền truy cập dữ liệu trong Firebase. Với ứng dụng StudyDocs, mục tiêu là đảm bảo:

- Chỉ người dùng đã đăng nhập mới có thể đọc/ghi dữ liệu.
- Người dùng chỉ thấy, sửa, xóa tài liệu thuộc về mình.
- File trong Cloud Storage cũng bị giới hạn theo người sở hữu.

Nếu không cấu hình đúng, dữ liệu có thể bị truy cập trái phép dù app đã có đăng nhập.

---

## 2. Tại sao Security Rules quan trọng?

Trong mô hình truyền thống, quyền truy cập thường phụ thuộc vào ứng dụng hoặc thiết bị. Trong cloud, dữ liệu nằm trên server của Firebase và mọi truy vấn đều có thể được gửi từ client. Vì vậy, Security Rules phải được dùng như lớp bảo vệ cuối cùng.

Nói ngắn gọn: **client có thể bị bypass, nhưng server-side rules không thể bị bypass**.

---

## 3. Nguyên tắc thiết kế Security Rules

### 3.1. Luôn yêu cầu xác thực

Các thao tác quan trọng như đọc/ghi document hoặc upload file nên yêu cầu:

- `request.auth != null`
- `request.auth.uid` phải tồn tại

### 3.2. Dùng `uid` làm khóa quyền sở hữu

Mỗi tài liệu nên có trường như:

```json
{
  "ownerId": "googleUid123",
  "title": "Bài giảng Toán",
  "createdAt": "2026-10-09T00:00:00Z"
}
```

Khi đó, quy tắc có thể kiểm tra:

```javascript
request.auth.uid == resource.data.ownerId
```

### 3.3. Không tin tưởng dữ liệu client

Không nên chỉ dựa vào `request.resource.data.ownerId` từ app nếu chưa kiểm tra chặt chẽ. Cần kiểm tra đúng trường dữ liệu và đảm bảo dữ liệu hợp lệ trước khi ghi.

---

## 4. Firestore Rules ví dụ

### 4.1. Quy tắc cơ bản

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /documents/{docId} {
      allow read: if request.auth != null
        && resource.data.ownerId == request.auth.uid;

      allow create: if request.auth != null
        && request.resource.data.ownerId == request.auth.uid
        && request.resource.data.keys().hasAll(['title', 'ownerId', 'createdAt']);

      allow update: if request.auth != null
        && resource.data.ownerId == request.auth.uid
        && request.resource.data.ownerId == request.auth.uid;

      allow delete: if request.auth != null
        && resource.data.ownerId == request.auth.uid;
    }
  }
}
```

### 4.2. Giải thích

- `allow read`: chỉ tài liệu do chính user sở hữu mới được đọc.
- `allow create`: chỉ user tạo mới có thể gán `ownerId` là chính mình.
- `allow update`: user chỉ được sửa tài liệu của mình.
- `allow delete`: chỉ xóa tài liệu của mình.

---

## 5. Storage Rules ví dụ

### 5.1. Quy tắc cơ bản

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5.2. Điều gì được bảo vệ?

- Mỗi user chỉ có thể truy cập thư mục tài liệu của chính mình.
- Người dùng không thể upload file vào tài khoản khác.
- File được lưu theo cách phân biệt theo `uid`, giúp ngăn chặn truy cập chéo.

---

## 6. Đề xuất cấu trúc lưu trữ theo user

Một cách thiết kế rõ ràng cho StudyDocs là lưu file theo userId như sau:

```text
/users/{uid}/documents/{documentId}.pdf
/users/{uid}/documents/{documentId}.docx
```

Điều này giúp:

- Dễ tách dữ liệu giữa user.
- Dễ viết Security Rules.
- Giảm rủi ro truy cập nhầm file của người khác.

---

## 7. Kết hợp Firestore và Storage

Trong StudyDocs, nên dùng cách kết hợp như sau:

1. User upload file lên `Cloud Storage`.
2. Firebase trả về `downloadUrl`.
3. Ứng dụng lưu `downloadUrl` và metadata vào Firestore.
4. Firestore Rules kiểm soát ai được đọc/ghi metadata.
5. Storage Rules kiểm soát ai được upload/download file.

Cách triển khai này giúp hệ thống có cả hai lớp bảo vệ: 
- **Firestore** bảo vệ metadata tài liệu.
- **Storage** bảo vệ file thực tế.

---

## 8. Một số lưu ý quan trọng

- Không để các collection chung không có kiểm soát quyền nếu không cần thiết.
- Nên kiểm tra `resource.data.ownerId` để tránh người dùng sửa dữ liệu của người khác.
- Với file upload, nên giới hạn loại file và dung lượng tối đa.
- Nếu cần phân quyền dựa trên vai trò, có thể bổ sung trường `role` và kiểm tra trong Rule.

Ví dụ giới hạn file hợp lệ:

```javascript
allow write: if request.auth != null
  && request.auth.uid == userId
  && request.resource.contentType.matches('application/pdf|application/vnd.openxmlformats-officedocument.wordprocessingml.document')
  && request.resource.size < 20 * 1024 * 1024;
```

---

## 9. Kết luận

Security Rules là lớp bảo vệ bắt buộc khi tích hợp Firebase vào ứng dụng quản lý tài liệu. Với StudyDocs, việc lưu trữ file và metadata theo user giúp giảm rủi ro đáng kể và đảm bảo tính riêng tư cho từng người dùng.

Nếu thiết kế Security Rules đúng, hệ thống không chỉ thuận tiện mà còn đáp ứng tiêu chuẩn an toàn của một ứng dụng cloud hiện đại.
