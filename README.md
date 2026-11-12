# LyMeowz Shader 🐾

Shader pack Minecraft Java chạy trên **Iris** (định dạng OptiFine, OpenGL), hướng tới ánh sáng điện ảnh và bầu trời vật lý.

> README này được viết dựa trên việc đọc mã nguồn. Các thông số mặc định là giá trị trong `settings.glsl`; hãy chỉnh theo máy và mắt của bạn.

## Tính năng

**Bầu trời & khí quyển**
- Tán xạ khí quyển theo vật lý (Rayleigh, Mie, ozone) dùng bảng LUT truyền sáng và đa tán xạ.
- Mây thể tích ray-march, có bầu trời phản xạ cho nước và vật liệu bóng.
- Mặt trời, mặt trăng, sao; sương mù khí quyển và ánh sáng thể tích.

**Ánh sáng & bóng**
- Bóng đổ mềm (tìm vật cản + PCF xoay), bóng màu xuyên kính màu, bóng không gian màn hình cho khoảng cách xa.
- GI gián tiếp kiểu **Reflective Shadow Maps**, khử nhiễu theo thời gian và song phương.
- Che khuất môi trường **GTAO** hoặc **SSAO**, có multi-bounce.
- Vật liệu PBR đọc từ specular map (kim loại, độ nhám, tán xạ dưới bề mặt, phát sáng), parallax mapping (mặc định tắt).

**Nước**
- Sóng procedural có parallax, khúc xạ, phản xạ không gian màn hình (SSR) kết hợp phản xạ bầu trời.
- Sương mù dưới nước, caustics, bóng xuyên nước.

**Hình ảnh cuối**
- TAA, làm nét FSR RCAS, anisotropic filtering.
- Bloom, tự động phơi sáng, bộ lọc màu, vignette.
- Tonemap: ACESFull, ACES, AgX, Hejl, Lottes, Hable, Neutral, Uchimura.
- Tùy chọn (mặc định tắt): motion blur, depth of field, letterbox.

**Khác**
- Cây cỏ và lá đung đưa.
- Hỗ trợ **Distant Horizons** (địa hình và nước xa).
- Có sẵn chương trình riêng cho Overworld, Nether và End.
- Giao diện tùy chọn có hai ngôn ngữ: **Tiếng Việt** và English; có 4 profile **Low / Medium / High / Ultra**.

## Cài đặt

1. Cài **Iris Shaders** (cùng Sodium) phù hợp phiên bản Minecraft của bạn. Shader cần card đồ họa hỗ trợ OpenGL hiện đại.
2. Tải repo này dưới dạng ZIP (hoặc nén thư mục chứa `shaders/` thành `.zip`).
3. Chép file ZIP vào thư mục `shaderpacks` của Minecraft.
4. Vào game: **Cài đặt Video → Shader Packs** → chọn `LyMeowz`.

Cấu trúc bắt buộc: thư mục `shaders/` nằm ngay trong gốc file ZIP, kèm các file trong `shaders/texture/` (noise 2D/3D và bảng LUT).

## Hiệu năng

Shader khá nặng (ray-march mây, RSM, GTAO, SSR). Nếu bị giật:
- Chọn profile **Low** hoặc **Medium** trong menu shader.
- Giảm `VOLUMETRIC_CLOUDS_*_SAMPLES`, `RSM_*_SAMPLES`, `shadowMapResolution`, `REFLECTION_SAMPLES`.
- Tắt `RSM_ENABLED`, `VOLUMETRIC_CLOUDS` hoặc AO nếu cần.

## Cấu trúc thư mục

```
shaders/
  shaders.properties, block.properties, entity.properties
  program/   mã GLSL chính (composite, deferred, gbuffers, shadow, dh_*)
  world0/ world-1/ world1/   stub cho Overworld / Nether / End
  lib/       thư viện dùng chung (khí quyển, ánh sáng, nước, camera...)
  texture/   noise và LUT
  lang/      en_us.lang, vi_vn.lang
```

## Giấy phép & ghi công

Mã gốc của LyMeowz Shader phát hành theo **giấy phép MIT** (xem [LICENSE](LICENSE)).

Một số kỹ thuật và đoạn mã được tham khảo từ công trình công khai của tác giả khác (Shadertoy, AMD FSR, glsl-tone-map, bài viết Zhihu/CSDN và các bài báo kỹ thuật...). Danh sách đầy đủ nằm ở phần *Third-party notices* trong [LICENSE](LICENSE). Các phần đó vẫn thuộc về tác giả gốc và có thể có giấy phép riêng.

## Góp ý & lỗi

Gặp lỗi biên dịch hoặc hình ảnh lạ? Mở một [issue](../../issues), kèm phiên bản Minecraft, Iris, card đồ họa và log của Iris nếu có.
