# Kernel

Kernel Linux de CosmicOS: **Linux 6.18 LTS** modificado.

```
kernel/
├── linux/      el kernel (6.18.60, solo arm64 y riscv)
├── configs/    defconfig de arm64 y riscv64
├── scripts/    purge-arch.sh: reproduce la purga sobre el árbol upstream
└── UPSTREAM    versión y commit de origen
```

## Qué se cambió respecto a upstream

- `arch/` reducido a `arm64`, `riscv` y `Kconfig`.
- Eliminado `fs/hostfs` (solo sirve a UML) y ajustadas las referencias en `fs/Makefile`, `drivers/ras/Kconfig` y `crypto/Kconfig`.
- Parámetros fijos en la compilación.

El resto se decide por Kconfig, no borrando carpetas.

## Compilar

Siempre fuera del árbol, para que arm64 y riscv64 convivan:

```sh
./cosmic-build kernel
```

## Licencia

GPL-2.0-only para el kernel (obligatorio, es el de Linux). Los scripts propios, GPL-3.0-or-later.
