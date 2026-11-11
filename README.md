# LyMeowz Shader 🐾  (v0.3.1)

Shader pack Minecraft tập trung vào **nước**, chạy trên **Iris** (định dạng OptiFine, backend OpenGL).
Toàn bộ code được viết mới từ đầu, không sao chép từ shader pack nào khác.

> ⚠️ **Trạng thái: v0.3.1, mới được chạy thử một lần.** Lần thử đầu báo lỗi biên dịch `RGBA16F` ở `composite.fsh` (đã sửa ở bản này).
> Cả 34 chương trình GLSL được kiểm tra biên dịch bằng `glslangValidator` (kể cả các biến thể bật/tắt từng tùy chọn),
> nhưng công cụ đó không biết các quy tắc riêng của Iris, nên vẫn có thể còn lỗi chỉ lộ ra trong game. Các thông số cân chỉnh (độ sáng, độ dốc sóng,
> bias bóng đổ, ngưỡng bloom...) là ước lượng ban đầu, cần chỉnh theo mắt khi test.
>
> **v0.3.1:** sửa lỗi biên dịch `undefined variable "RGBA16F"`: khai báo format buffer (`colortexNFormat`) giờ nằm trong chú thích để Iris đọc mà GLSL không biên dịch.
> **v0.3:** bóng đổ nâng cấp (bóng màu qua kính màu, bias và normal offset chỉnh được trong menu), bảng phiên bản 26.1–26.4.
> **v0.2:** caustics dưới nước, mây procedural (nước phản chiếu mây), bloom, nhiễu tĩnh thay cho nhiễu đổi theo khung hình.

## Hiệu ứng nước

- **Sóng procedural**: nhiều lớp noise gợn sóng + domain warping, chuyển động theo thời gian, số lớp chỉnh được.
- **Parallax sóng**: tìm đúng điểm tia nhìn chạm mặt sóng nên sóng có chiều sâu khi nhìn nghiêng.
- **Khúc xạ**: lệch ảnh đáy nước theo độ nghiêng của pháp tuyến sóng, có kiểm tra để không kéo vào vật thể nằm trước mặt nước.
- **Hấp thụ & tán xạ theo độ sâu** (Beer-Lambert): đỏ biến mất trước, nước sâu chuyển dần sang xanh. 4 preset màu.
- **Caustics**: mạng vệt sáng chuyển động dưới đáy, uốn theo sóng thật, trượt theo độ sâu và hướng nắng, bị chặn bởi bóng đổ. Hoạt động cả khi nhìn từ trên xuống lẫn khi camera ở dưới nước; sàn nhận nhiều hơn tường nhờ pháp tuyến dựng lại từ depth.
- **Phản xạ**: Fresnel (Schlick) trộn phản xạ bầu trời (có cả **mây**) với **SSR** (ray-march + tinh chỉnh nhị phân), cổng theo ánh sáng bầu trời để hang động không phản chiếu trời.
- **Ánh nắng lấp lánh** (GGX) cho mặt trời và mặt trăng.
- **Bọt sóng ven bờ** ở vùng nước nông.
- **Gợn nước khi mưa**: vòng tròn lan rộng trên mặt nước ngoài trời.
- **Dưới nước**: sương mù hấp thụ/tán xạ, cửa sổ Snell (thấy cả mây qua đó) và phản xạ toàn phần khi nhìn lên mặt nước.
- **Bloom**: ánh nắng lấp lánh trên nước và các điểm sáng HDR tỏa sáng mềm (4 pass, ngưỡng theo độ sáng HDR).

Phần còn lại là nền tối thiểu để nước có thứ để phản chiếu: bầu trời procedural kèm **mây procedural**, bóng đổ (PCF xoay, bóng màu),
ánh sáng mặt trời/trăng, đuốc, sương mù khoảng cách, tonemap filmic. Nhiễu (bóng, SSR) là nhiễu tĩnh vì chưa có TAA,
nên không bị nhấp nháy theo từng khung hình.

## Yêu cầu

Pack này là shader định dạng OptiFine thuần (GLSL), **không phụ thuộc phiên bản Minecraft**: nó chạy được trên bất kỳ
bản nào mà **Iris** hỗ trợ. Bảng dưới là các bản Iris/Sodium (Fabric) tra cứu ngày 11/11/2026:

| Minecraft | Iris | Sodium | Ghi chú |
|---|---|---|---|
| 26.1.x | 1.10.9, hoặc 1.11.4 (cho 26.1.2) | 0.8.x với Iris 1.10.9; 0.9.2 với Iris 1.11.4 | Iris 1.10.9 sửa nhiều lỗi shader pack phát sinh từ 26.1 |
| 26.2 | 1.11.4 | 0.9.2 | Có backend Vulkan thử nghiệm, Iris không chạy trên đó |
| 26.3 | 1.11.7 | 0.9.2 | Bản mới nhất có Iris |
| 26.4 | chưa có | chưa có | Mới ở giai đoạn snapshot, trang Iris trên Modrinth chưa liệt kê 26.4 |

Chung cho mọi bản: Fabric Loader 0.19.5 trở lên, Java 25.

**Về 26.4:** snapshot 2 đổi cách vẽ bầu trời (một "sky occluder" che nửa dưới skybox, kèm fog và Improved
Transparency mới). Pack vẽ bầu trời procedural trong `gbuffers_skybasic` nên phần đó dự kiến tương thích, nhưng
**chưa được kiểm chứng** vì chưa có Iris cho 26.4. Khi Iris ra bản 26.4, hãy thử lại và báo mình nếu trời/mặt trời bị lỗi.

**Quan trọng:** Iris chỉ chạy trên **OpenGL**. Từ 26.2 game có backend Vulkan thử nghiệm; nếu bật
*Video Settings → Graphics API → Prefer Vulkan* thì shader sẽ tự tắt. Hãy để OpenGL.

## Bóng đổ

- Shadow map có méo (nhiều độ phân giải hơn gần người chơi), lấy mẫu PCF xoay 8 điểm, đẩy điểm lấy mẫu theo pháp tuyến để chống acne.
- **Bóng màu**: ánh sáng đi qua kính màu, băng, slime... mang màu của chúng (tùy chọn *Colored Shadows*).
- Nước không đổ bóng (nước trong suốt, ánh nắng vẫn xuống tới đáy để tạo caustics).
- Địa hình, thực thể, block entity và cả người chơi đều được vẽ vào shadow map.
- Nếu thấy bóng bị sọc/lốm đốm (acne): tăng *Shadow Bias* hoặc *Shadow Normal Offset*. Nếu bóng tách rời khỏi vật thể: giảm hai giá trị đó.
- Không thấy bóng: kiểm tra *Shadows* đang bật, *Shadow Distance* khác 0, và game đang dùng backend OpenGL.

## Cài đặt

1. Cài Fabric + Iris + Sodium (cách dễ nhất là Iris Installer).
2. Chép thư mục `shaders/` của repo này vào `.minecraft/shaderpacks/LyMeowzShader/`
   (hoặc nén thành `.zip` sao cho `shaders/` nằm ngay ở gốc file zip).
   Lưu ý: nút *Download ZIP* của GitHub bọc thêm một thư mục bên ngoài nên Iris sẽ không nhận trực tiếp.
3. Vào *Options → Video Settings → Shader Packs*, chọn **LyMeowzShader**.

## Cấu trúc

```
shaders/
├── shaders.properties, block.properties, lang/   cấu hình, id block nước, ngôn ngữ (en, vi)
├── lib/
│   ├── settings.glsl      toàn bộ tùy chọn (hiện trong menu Iris)
│   ├── waves.glsl         sóng, parallax, gợn mưa, caustics, preset màu nước
│   ├── sky.glsl           bầu trời, màu nắng/trăng, ambient
│   ├── clouds.glsl        mây procedural (vẽ trên trời + phản chiếu trên nước)
│   ├── depth.glsl         dựng vị trí/pháp tuyến từ depth
│   ├── shadow*.glsl       méo shadow map + lấy mẫu bóng
│   ├── lighting.glsl      ánh sáng forward dùng chung
│   └── common.glsl        toán, hash PCG, noise
├── shadow.*               shadow map (nước không đổ bóng)
├── gbuffers_*             vẽ hình học đã chiếu sáng (HDR) vào colortex0
├── gbuffers_water.*       ghi pháp tuyến sóng vào colortex3/4; kính/băng vẫn blend bình thường
├── composite.fsh          ⭐ shading nước: khúc xạ, hấp thụ, caustics, SSR, specular, bọt
├── composite1.fsh         sương mù + hiệu ứng dưới nước (kèm caustics)
├── composite2-5.fsh       bloom: bright pass + 2 lần blur hẹp + 2 lần blur rộng
└── final.fsh              bloom, tonemap, saturation, vignette
```

Luồng nước: `gbuffers_water` chỉ ghi pháp tuyến sóng (alpha màu = 0 nên không đè cảnh) → `composite` đọc
pháp tuyến + depth (`depthtex0` có nước, `depthtex1` không có) để dựng toàn bộ vẻ ngoài của mặt nước.

## Giới hạn đã biết / việc tiếp theo

- Caustics dưới nước dựa trên giả định "mọi thứ thấp hơn mắt đều ngập nước" (shader không biết độ cao mặt nước), nên vệt sáng sẽ mờ dần ở ngang tầm mắt.
- Mây là lớp 2D procedural và thay thế hoàn toàn mây vanilla (`clouds=off`); tắt *Procedural Clouds* thì sẽ không còn mây. Sprite mặt trời/mặt trăng của vanilla vẫn được vẽ đè lên mây.
- Chưa có TAA, mây volumetric, AO, GI, wetness trên địa hình, hiệu ứng ánh sáng màu.
- Chỉ nhận water là `minecraft:water` (id 10001); nước của mod khác chưa được map.
- Không hỗ trợ Distant Horizons (`dh_*`) và Vulkan.
- `gl_Color` của terrain được dùng làm AO + tint; nếu thấy mặt block bị tối bất thường, báo lại để chỉnh.

## Giấy phép

Chưa chọn giấy phép. Hãy thêm file `LICENSE` phù hợp trước khi chia sẻ rộng rãi.
