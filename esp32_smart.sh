#!/data/data/com.termux/files/usr/bin/bash

VERSION="1.1.0"
echo "================================================="
echo "🚀 أداة ESP32 Mobile Studio (الإصدار الذكي $VERSION)"
echo "================================================="
echo "جاري فحص بيئة الهاتف..."
echo ""

# دالة للتحقق من وجود أمر معين
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ==========================================
# 1. فحص وتثبيت Python و Socat
# ==========================================
if ! command_exists python; then
    echo "⏳ [فحص] Python غير موجود. جاري تثبيته..."
    pkg install python -y > /dev/null 2>&1
else
    echo "✅ [فحص] Python مثبت بالفعل."
fi

if ! command_exists socat; then
    echo "⏳ [فحص] Socat غير موجود. جاري تثبيته..."
    pkg install socat -y > /dev/null 2>&1
else
    echo "✅ [فحص] Socat مثبت بالفعل."
fi

if ! command_exists termux-usb; then
    echo "⏳ [فحص] Termux:API غير موجود. جاري تثبيته..."
    pkg install termux-api -y > /dev/null 2>&1
else
    echo "✅ [فحص] Termux:API مثبت بالفعل."
fi

# ==========================================
# 2. فحص وتثبيت مكتبات Python
# ==========================================
echo "⏳ [فحص] جاري التحقق من مكتبات Python (mpremote, rp2040py)..."

# التحقق من وجود mpremote
if ! command_exists mpremote; then
    echo "⏳ [فحص] مكتبة mpremote غير موجودة. جاري تثبيتها..."
    pip install mpremote --quiet > /dev/null 2>&1
else
    echo "✅ [فحص] mpremote مثبت بالفعل."
fi

# التحقق من وجود rp2040py
if ! python -c "import rp2040py" >/dev/null 2>&1; then
    echo "⏳ [فحص] مكتبة rp2040py غير موجودة. جاري تثبيتها..."
    pip install rp2040py --quiet > /dev/null 2>&1
else
    echo "✅ [فحص] rp2040py مثبت بالفعل."
fi

# ==========================================
# 3. التحقق من TCPUART
# ==========================================
echo ""
echo "⏳ [فحص] جاري التحقق من اتصال TCPUART..."
if ! timeout 2 bash -c "</dev/tcp/127.0.0.1/8080" 2>/dev/null; then
    echo "❌ خطأ: TCPUART غير مفتوح أو لم يتم تشغيل Server."
    echo "👉 يرجى فتح تطبيق TCPUART، والضغط على Connect ثم Start (Port 8080)."
    exit 1
fi
echo "✅ TCPUART متصل."

# ==========================================
# 4. حلقة الرفع
# ==========================================
echo ""
echo "================================================="
echo "🎉 كل شيء جاهز! الأداة تعمل الآن."
echo "================================================="

while true; do
    echo ""
    echo "📝 اكتب الكود الخاص بك (بايثون) واضغط Enter."
    echo "عندما تنتهي، اكتب كلمة END في سطر جديد للرفع."
    echo "-------------------------------------------------"
    
    > main.py
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        echo "$line" >> main.py
    done
    
    echo "🚀 جاري رفع الكود إلى ESP32..."
    rp2040py mpremote connect socket://127.0.0.1:8080 fs cp main.py :main.py
    
    if [ $? -eq 0 ]; then
        echo "🎉 نجح الرفع! اضغط زر RST على اللوحة لرؤية النتيجة."
    else
        echo "❌ فشل الرفع. تأكد من أن TCPUART يعمل."
    fi
    
    echo ""
    echo "هل تريد رفع كود آخر؟ (اضغط Enter للمتابعة، أو اكتب 'exit' للخروج)"
    read -r continue_choice
    if [ "$continue_choice" = "exit" ]; then
        echo "👋 مع السلامة!"
        break
    fi
done
