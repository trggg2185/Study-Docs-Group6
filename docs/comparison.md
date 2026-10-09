# So sánh mô hình truyền thống và Cloud cho StudyDocs

## 1. Mục tiêu

Tài liệu này so sánh cách hệ thống quản lý tài liệu học tập hoạt động trong mô hình truyền thống (lưu cục bộ trên thiết bị) và mô hình Cloud (Firebase) để đánh giá mức độ hiệu quả, độ an toàn và khả năng mở rộng của từng phương án.

---

## 2. Bảng so sánh truyền thống vs Cloud

| Tiêu chí | Mô hình truyền thống | Mô hình Cloud (Firebase) |
|---|---|---|
| **Lưu trữ dữ liệu** | Dữ liệu được lưu trực tiếp trên SQLite / bộ nhớ thiết bị | Firestore lưu metadata, Cloud Storage lưu file |
| **Quản lý file** | File nằm trên máy local, dễ bị mất nếu thay máy hoặc format thiết bị | File được lưu trên cloud, truy cập từ mọi thiết bị |
| **Xác thực người dùng** | Không có hoặc chỉ là kiểm soát phần cứng/ứng dụng | Firebase Authentication hỗ trợ đăng nhập Google, session quản lý tự động |
| **Truy cập từ xa** | Không thể truy cập ngoài thiết bị hiện tại | Có thể truy cập qua internet nếu được cấp quyền |
| **Đồng bộ đa thiết bị** | Không có cơ chế đồng bộ | Firestore + offline persistence hỗ trợ sync tự động |
| **Backup & recovery** | Khó hoặc không có | Có thể dự phòng tự động trên nền tảng cloud |
| **Chia sẻ dữ liệu** | Khó chia sẻ, thường phải copy file thủ công | Có thể phân quyền theo user với Security Rules |
| **Bảo mật** | Dựa trên thiết bị, dễ rủi ro nếu người khác cài app trên cùng máy | Có xác thực và kiểm soát truy cập theo role/user |
| **Hiệu suất** | Tốt cho thao tác local, nhưng không phù hợp khi cần đồng bộ nhiều thiết bị | Tốt cho app đa người dùng, cần tối ưu query và cấu trúc dữ liệu |
| **Chi phí** | Ban đầu thấp nhưng phát sinh từ mất dữ liệu/thiết bị | Có thể miễn phí ở mức cơ bản, tăng dần khi scale lớn |
| **Tính mở rộng** | Hạn chế về dung lượng và khả năng quản lý | Dễ mở rộng theo số lượng người dùng và dữ liệu |
| **Khả năng bảo trì** | Phụ thuộc vào thiết bị và người dùng | Dễ quản lý hơn, có tài liệu và SDK hỗ trợ |

---

## 3. Phân tích theo từng khía cạnh

### 3.1. Về lưu trữ

Trong mô hình truyền thống, StudyDocs dùng SQLite để lưu metadata tài liệu và file trên bộ nhớ thiết bị. Lợi ích của cách này là đơn giản, không cần backend, tốc độ truy cập cao khi dữ liệu chỉ nằm trên máy. Tuy nhiên, nó không phù hợp nếu người dùng cần truy cập tài liệu từ điện thoại khác, máy tính khác hoặc khi thiết bị bị mất.

Với mô hình Cloud, metadata được lưu ở Firestore, còn file tài liệu lưu trên Cloud Storage. Cách này tách rõ hai lớp: dữ liệu dạng cấu trúc (metadata) và dữ liệu dạng nhị phân (file). Kết quả là hệ thống dễ mở rộng và dễ quản lý hơn.

### 3.2. Về xác thực và quyền truy cập

Mô hình truyền thống thường không kiểm soát ai có thể xem hoặc chỉnh sửa tài liệu. Nếu ứng dụng cài trên cùng thiết bị, mọi người có thể truy cập vào dữ liệu nếu biết đường dẫn hoặc vào được ứng dụng.

Firebase cung cấp Firebase Authentication và Security Rules để xác thực người dùng và kiểm soát dữ liệu theo `uid`. Đây là lợi thế lớn cho ứng dụng quản lý tài liệu học tập, vì mỗi sinh viên hoặc người dùng cần chỉ xem những tài liệu thuộc về mình.

### 3.3. Về đồng bộ và truy cập đa thiết bị

Mô hình truyền thống không hỗ trợ đồng bộ. Nếu người dùng dùng 2 điện thoại, dữ liệu trên máy 1 không xuất hiện trên máy 2. Điều này làm mất tính thuận tiện trong học tập và cộng tác.

Firestore hỗ trợ real-time sync và offline persistence, giúp app có thể cập nhật dữ liệu ngay khi đang có mạng hoặc khi mất mạng rồi tự đồng bộ sau đó.

### 3.4. Về chi phí và bảo trì

Hệ thống truyền thống có vẻ rẻ vì không cần backend, nhưng thực tế vẫn phát sinh chi phí theo thời gian: mất dữ liệu, sao lưu thủ công, xử lý lỗi trên từng thiết bị, và khó triển khai thay đổi trên quy mô lớn.

Firebase có chi phí theo mức sử dụng, nhưng ở giai đoạn học tập, Spark Plan đủ đáp ứng nhu cầu cơ bản. Đặc biệt với bài tập, đây là lựa chọn hợp lý vì giảm đáng kể thời gian setup và tập trung vào giá trị nghiệp vụ.

---

## 4. Kết luận

So với mô hình truyền thống, mô hình Cloud đem lại các lợi ích rõ rệt hơn trong bối cảnh ứng dụng StudyDocs:

- Dữ liệu an toàn hơn nhờ xác thực và quyền truy cập.
- Dễ đồng bộ, truy cập từ nhiều thiết bị.
- Dễ mở rộng khi số lượng user và file tăng lên.
- Giảm rủi ro mất dữ liệu do hỏng thiết bị.

Vì vậy, tích hợp Firebase là lựa chọn phù hợp cho ứng dụng quản lý tài liệu học tập, đặc biệt khi cần có tính cộng đồng, hiệu quả và bảo mật hơn so với lưu trữ hoàn toàn cục bộ.
