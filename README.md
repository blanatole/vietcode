# VietCode

VietCode là một CLI đa nền tảng dùng để bọc Claude Code và chuyển request qua VietAPI.

## Tính năng

- Cài đặt bằng một lệnh duy nhất
- Khi cài chỉ hỏi API key
- Tự cài Claude Code CLI nếu máy chưa có
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

> Khi cài, VietCode sẽ tự kiểm tra lệnh `claude`. Nếu máy chưa có, installer sẽ tự chạy:
>
> ```bash
> npm install -g @anthropic-ai/claude-code
> ```

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
4. kiểm tra `claude`, nếu chưa có thì tự cài `@anthropic-ai/claude-code`
5. hỏi API key của bạn
6. đặt model mặc định là `gpt-5.4`

### Cài non-interactive bằng biến môi trường

Nếu bạn đang chạy trên server hoặc môi trường không tiện nhập tay API key:

```bash
VIETCODE_API_KEY=YOUR_API_KEY curl -fsSL https://raw.githubusercontent.com/blanatole/vietcode/main/install.sh | bash
```

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
npm install -g @anthropic-ai/claude-code
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
   - máy chưa có `claude`
   - có `claude` trong `PATH`
   - chỉ có editor extension
   - có `CLAUDE_CODE_BIN`
   - thiếu API key
   - chọn model sai
