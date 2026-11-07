#!/usr/bin/env bash
#
# purge-arch.sh — Purga reproducible del árbol arch/ en Linux para CosmicOS
#
# Propósito (CosmicOS spec v0.2.8):
# 1. Eliminar todas las arquitecturas del kernel Linux upstream, manteniendo
#    únicamente ARM64 y RISC-V, más los archivos Kconfig y .gitignore.
# 2. Ajustar referencias cruzadas a Kconfig en crypto/Kconfig y drivers/ras/Kconfig
#    que referenciaban arquitecturas purgadas.
#
# Permite verificar de forma determinista que el fork de OpenCosmicProject
# equivale a upstream + purga y nada más.
#

set -euo pipefail

# Determinar raíz del kernel
if [ -d "kernel/linux/arch" ]; then
    KERNEL_ROOT="kernel/linux"
elif [ -d "arch" ] && [ -f "Kbuild" ]; then
    KERNEL_ROOT="."
else
    echo "Error: No se encontró el directorio del kernel Linux." >&2
    echo "Ejecute este script desde la raíz del proyecto o desde kernel/linux/" >&2
    exit 1
fi

ARCH_DIR="$KERNEL_ROOT/arch"
echo "==> Purgando arquitecturas no soportadas en: $ARCH_DIR"
echo "==> Arquitecturas y archivos preservados: arm64, riscv, Kconfig, .gitignore"

KEPT_ITEMS=("arm64" "riscv" "Kconfig" ".gitignore")

shopt -s nullglob dotglob
for item in "$ARCH_DIR"/*; do
    name="$(basename "$item")"
    keep=0
    for k in "${KEPT_ITEMS[@]}"; do
        if [ "$name" = "$k" ]; then
            keep=1
            break
        fi
    done

    if [ $keep -eq 0 ]; then
        echo "  [BORRANDO] $item"
        rm -rf "$item"
    else
        echo "  [PRESERVANDO] $item"
    fi
done

# Ajustar drivers/ras/Kconfig si contiene referencia a arch/x86/ras/Kconfig
RAS_KCONFIG="$KERNEL_ROOT/drivers/ras/Kconfig"
if [ -f "$RAS_KCONFIG" ] && grep -q 'source "arch/x86/ras/Kconfig"' "$RAS_KCONFIG"; then
    echo "==> Ajustando $RAS_KCONFIG para omitir inclusión de arch/x86 purgada..."
    sed -i 's|source "arch/x86/ras/Kconfig"|# source "arch/x86/ras/Kconfig" (purga CosmicOS)|g' "$RAS_KCONFIG"
fi

# Ajustar crypto/Kconfig para incluir solo ARM64 y RISCV
CRYPTO_KCONFIG="$KERNEL_ROOT/crypto/Kconfig"
if [ -f "$CRYPTO_KCONFIG" ] && grep -q 'source "arch/arm/crypto/Kconfig"' "$CRYPTO_KCONFIG"; then
    echo "==> Ajustando $CRYPTO_KCONFIG para conservar solo crypto de ARM64 y RISC-V..."
    sed -i '/if ARM$/,/endif$/d' "$CRYPTO_KCONFIG"
    sed -i '/if LOONGARCH$/,/endif$/d' "$CRYPTO_KCONFIG"
    sed -i '/if MIPS$/,/endif$/d' "$CRYPTO_KCONFIG"
    sed -i '/if PPC$/,/endif$/d' "$CRYPTO_KCONFIG"
    sed -i '/if S390$/,/endif$/d' "$CRYPTO_KCONFIG"
    sed -i '/if SPARC$/,/endif$/d' "$CRYPTO_KCONFIG"
    sed -i '/if X86$/,/endif$/d' "$CRYPTO_KCONFIG"
fi

echo "==> Purga de arch/ completada con éxito."
echo "==> Estado actual de $ARCH_DIR:"
ls -la "$ARCH_DIR"
