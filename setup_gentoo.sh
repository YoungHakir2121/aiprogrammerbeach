#!/bin/bash

# Проверка прав root
if [ "$(id -u)" != "0" ]; then
    echo "Этот скрипт должен быть запущен с правами root" 1>&2
    exit 1
fi

# Обновление системы перед установкой
echo "Обновляю систему..."
emerge --sync && emerge -uD @world || {
    echo "Ошибка при обновлении системы. Прерываю выполнение."
    exit 1
}

# Установка утилит для определения оборудования, если они отсутствуют
echo "Устанавливаю необходимые утилиты (pciutils, usbutils, lshw)..."
emerge --ask --quiet pciutils usbutils lshw || {
    echo "Ошибка при установке утилит."
    exit 1
}

### Определение и установка драйверов для видеокарты ###
echo "Определяю видеокарту..."
VGA=$(lspci | grep -i vga | awk '{print $5}')

if [[ $VGA =~ "NVIDIA" ]]; then
    echo "Обнаружена видеокарта NVIDIA. Устанавливаю драйвер..."
    emerge --ask --quiet x11-drivers/nvidia-drivers || {
        echo "Ошибка при установке драйвера NVIDIA."
        exit 1
    }
elif [[ $VGA =~ "Advanced" ]]; then  # AMD
    echo "Обнаружена видеокарта AMD. Устанавливаю драйвер..."
    emerge --ask --quiet x11-drivers/ati-drivers || {
        echo "Ошибка при установке драйвера AMD."
        exit 1
    }
elif [[ $VGA =~ "Intel" ]]; then
    echo "Обнаружена видеокарта Intel. Драйвер уже встроен в ядро."
else
    echo "Неизвестная видеокарта: $VGA. Пропускаю установку драйвера."
fi

### Определение и установка драйверов для сетевых карт ###
echo "Определяю сетевые устройства..."
NETWORK=$(lspci | grep -i ethernet)

if [[ -n "$NETWORK" ]]; then
    echo "Обнаружено сетевое устройство: $NETWORK"
    # Большинство сетевых драйверов встроены в ядро, но можно установить firmware, если требуется
    echo "Устанавливаю linux-firmware для поддержки сетевых устройств..."
    emerge --ask --quiet sys-kernel/linux-firmware || {
        echo "Ошибка при установке linux-firmware."
        exit 1
    }
else
    echo "Сетевые устройства не обнаружены."
fi

### Установка базового софта ###
echo "Устанавливаю Xorg для графической среды..."
emerge --ask --quiet x11-base/xorg-server || {
    echo "Ошибка при установке Xorg."
    exit 1
}

echo "Устанавливаю окружение рабочего стола KDE Plasma..."
emerge --ask --quiet kde-plasma/plasma-meta || {
    echo "Ошибка при установке KDE Plasma."
    exit 1
}

### Завершение ###
echo "Установка драйверов и софта завершена успешно!"
echo "Рекомендуется перезагрузить систему: reboot"