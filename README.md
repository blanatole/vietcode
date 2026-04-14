# VietCode

VietCode là một CLI đa nền tảng dùng để bọc Claude Code và chuyển request qua VietAPI.

## Tính năng

- Cài đặt bằng một lệnh duy nhất
- Khi cài chỉ hỏi API key
- Chỉ cho phép 3 model:
  - `gpt-5.4`
  - `gpt-5.3-codex`
  - `gpt-5.2`
- Tự dò Claude Code binary từ các vị trí phổ biến
- Hỗ trợ override binary bằng biến `CLAUDE_CODE_BIN`
- Có lệnh `doctor` để kiểm tra môi trường cục bộ

## Yêu cầu

- `git`
- Node.js 18 trở lên
- `npm`
- Claude Code đã được cài theo một trong các cách sau:
  - có lệnh `claude` trong `PATH`
  - hoặc được cài qua extension được hỗ trợ

## Cài đặt

### Cài bằng 1 lệnh

Nếu dùng GitHub raw:

```bash
curl -fsSL https://raw.githubusercontent.com/blanatole/vietcode/main/install.sh | bash
```

Nếu dùng GitHub Pages:

```bash
curl -fsSL https://blanatole.github.io/vietcode/install.sh | bash
```

Script sẽ tự động:

1. clone repo về `~/.vietcode-cli`
2. cài dependencies
3. chạy `npm link` để tạo lệnh `vietcode`
4. hỏi API key của bạn
5. đặt model mặc định là `gpt-5.4`

### Đổi repo nguồn hoặc thư mục cài

Đổi repo clone:

```bash
VIETCODE_REPO_URL=https://github.com/blanatole/vietcode.git curl -fsSL https://raw.githubusercontent.com/blanatole/vietcode/main/install.sh | bash
```

Đổi thư mục cài:

```bash
VIETCODE_INSTALL_DIR=$HOME/.local/vietcode curl -fsSL https://raw.githubusercontent.com/blanatole/vietcode/main/install.sh | bash
```

### Cài thủ công từ repo

```bash
git clone https://github.com/blanatole/vietcode.git
cd vietcode
npm install
npm link
vietcode config --key YOUR_API_KEY
vietcode model gpt-5.4
```

## Cách dùng

### Chạy VietCode

```bash
vietcode
```

### Cấu hình API key

```bash
vietcode config --key YOUR_API_KEY
```

### Đổi base URL

```bash
vietcode config --base https://vietapi.tech
```

### Xem model hiện tại

```bash
vietcode model
```

### Đổi model

```bash
vietcode model gpt-5.4
vietcode model gpt-5.3-codex
vietcode model gpt-5.2
```

### Kiểm tra môi trường

```bash
vietcode doctor
```

## Cách VietCode tìm Claude binary

VietCode sẽ tìm Claude theo thứ tự:

1. `CLAUDE_CODE_BIN`
2. lệnh `claude` trong `PATH`
3. các thư mục extension được hỗ trợ trong thư mục home

Nếu không tự tìm được, bạn có thể chạy:

```bash
CLAUDE_CODE_BIN=/path/to/claude vietcode
```

## Các model được hỗ trợ

Chỉ chấp nhận 3 model sau:

- `gpt-5.4`
- `gpt-5.3-codex`
- `gpt-5.2`

Nếu cấu hình model không hợp lệ, VietCode sẽ tự quay về `gpt-5.4`.

## Checklist publish npm

1. Kiểm tra tên package còn dùng được trên npm hay không.
2. Xem trước package sẽ publish:
   ```bash
   npm pack --dry-run
   ```
3. Đăng nhập npm:
   ```bash
   npm login
   ```
4. Publish package:
   ```bash
   npm publish
   ```
5. Test cài global trên máy sạch:
   ```bash
   npm install -g vietcode
   vietcode doctor
   ```

Nếu tên `vietcode` đã bị dùng, bạn có thể publish dưới dạng scope như `@vietcode/cli`.

## Checklist deploy installer

1. Push repo này lên GitHub.
2. Host file `install.sh` bằng một trong hai cách:
   - GitHub Pages
   - raw GitHub URL
3. Test installer trên:
   - macOS
   - Ubuntu
   - một bản Linux khác nếu cần
4. Kiểm tra các trường hợp sau:
   - có `claude` trong `PATH`
   - chỉ có editor extension
   - có `CLAUDE_CODE_BIN`
   - thiếu API key
   - chọn model sai
