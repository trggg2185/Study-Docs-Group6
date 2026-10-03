package com.example.profileapp

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton

/**
 * ACTIVITY CHÍNH: MainActivity
 *
 * Chức năng:
 * 1. Khởi tạo giao diện từ file XML (activity_main.xml)
 * 2. Ánh xạ các View từ XML vào code Kotlin
 * 3. Lập trình xử lý sự kiện Click cho các Button
 * 4. Kích hoạt Intent ngầm định (Implicit Intent) để mở liên kết web hoặc ứng dụng bên ngoài
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Gán giao diện XML cho Activity
        setContentView(R.layout.activity_main)

        // 1. ÁNH XẠ CÁC VIEW BUTTON TỪ FILE LAYOUT XML THEO ID
        val btnGithub: MaterialButton = findViewById(R.id.btnGithub)
        val btnFacebook: MaterialButton = findViewById(R.id.btnFacebook)
        val btnLinkedin: MaterialButton = findViewById(R.id.btnLinkedin)
        val btnEmail: MaterialButton = findViewById(R.id.btnEmail)

        // 2. LẬP TRÌNH SỰ KIỆN CLICK CHO TỪNG NÚT BẤM (setOnClickListener)

        // Sự kiện click nút GitHub -> Mở trang GitHub cá nhân
        btnGithub.setOnClickListener {
            openWebUrl("https://github.com/trggg2195")
        }

        // Sự kiện click nút Facebook -> Mở trang cá nhân Facebook
        btnFacebook.setOnClickListener {
            openWebUrl("https://facebook.com")
        }

        // Sự kiện click nút LinkedIn -> Mở trang mạng xã hội việc làm LinkedIn
        btnLinkedin.setOnClickListener {
            openWebUrl("https://linkedin.com")
        }

        // Sự kiện click nút Email -> Mở ứng dụng Gmail hoặc Email có sẵn trên thiết bị
        btnEmail.setOnClickListener {
            openEmailClient("truongyukihara@gmail.com")
        }
    }

    /**
     * PHƯƠNG THỨC: openWebUrl
     *
     * Chức năng: Sử dụng Intent ngầm định (Implicit Intent) với Action là ACTION_VIEW
     * để yêu cầu hệ điều hành Android tìm và mở trình duyệt web (Chrome, Edge, Samsung Internet...).
     *
     * @param url Đường dẫn trang web cần truy cập
     */
    private fun openWebUrl(url: String) {
        try {
            // Khởi tạo Intent với hành động ACTION_VIEW và dữ liệu URI phân tích từ chuỗi URL
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))

            // Gửi Intent tới hệ điều hành Android để kích hoạt ứng dụng phù hợp
            startActivity(intent)
        } catch (e: Exception) {
            // Bắt lỗi nếu thiết bị không có trình duyệt hoặc liên kết không hợp lệ
            Toast.makeText(this, "Không thể mở liên kết: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * PHƯƠNG THỨC: openEmailClient
     *
     * Chức năng: Sử dụng Intent với giao thức "mailto:" để mở hộp thoại gửi thư
     *
     * @param emailAddress Địa chỉ email người nhận
     */
    private fun openEmailClient(emailAddress: String) {
        try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("mailto:$emailAddress")
                putExtra(Intent.EXTRA_SUBJECT, "Liên hệ từ ứng dụng Profile")
            }
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Không tìm thấy ứng dụng gửi Email trên máy!", Toast.LENGTH_SHORT).show()
        }
    }
}

