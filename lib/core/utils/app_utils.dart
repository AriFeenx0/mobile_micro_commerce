/// รวมฟังก์ชันช่วยทั่วไปที่ใช้ร่วมกันในแอป
abstract final class AppUtils {
  /// ตัดช่องว่างหัวท้ายและแปลงข้อความค้นหาเป็นตัวพิมพ์เล็ก
  static String normalizeSearchText(String value) => value.trim().toLowerCase();
}