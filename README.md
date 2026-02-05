# 👾 512-Byte Space Invaders (Boot Sector)

This is a functional clone of the classic **Space Invaders** game, written entirely in x86 Assembly (NASM). The entire game fits within the **512-byte** boot sector of a disk, meaning it runs directly on hardware without the need for an operating system.

## ✨ Features

* 🚀 **Ultra-Compact:** Fits in exactly 512 bytes with the required `0xAA55` boot signature.
* 🎨 **Graphics:** Uses VGA Mode 13h (320x200 resolution, 256 colors).
* 👾 **Gameplay Mechanics:**
    * Animated alien sprites that move and shift downwards.
    * Destructible bunkers/barriers using bitmask manipulation.
    * Projectile system for both the player and the aliens.
    * Increasing difficulty as aliens speed up when they hit screen edges.
* 💻 **Technical Minimalism:** Direct video memory access (segment `0A000h`) and BIOS interrupt handling.

## 🎮 Controls

The game reads BIOS keyboard flags (interrupt `16h`) to allow for simultaneous key presses. Use the following modifier keys:

| Key | Action |
| :--- | :--- |
| **Left Shift** | Move Left ⬅️ |
| **Right Shift** | Move Right ➡️ |
| **Alt (Left/Right)** | Fire Shot 🔥 |

---

## 🛠 Compilation & Build

You will need the **NASM** (Netwide Assembler) to compile the source code.

1.  **Assemble the code** into a raw binary file:
    ```bash
    nasm -f bin game.asm -o game.bin
    ```
2.  **Verify the size:** The resulting `game.bin` must be exactly 512 bytes.

## 🚀 How to Run

### Using QEMU (Recommended)
You can run the binary in an emulator:

qemu-system-i386 -fda game.bin
Running on Real Hardware
Warning: This involves writing to the boot sector of a drive. Be extremely careful.

Identify your USB drive path (e.g., /dev/sdX).

Write the binary using dd:

Bash

sudo dd if=game.bin of=/dev/sdX bs=512 count=1
Boot from the USB in Legacy BIOS mode.

🧠 Technical Overview
Memory Layout: The code is loaded at 0x7C00. Variables and sprite data are stored in high memory (starting at 0xFA00) to prevent overwriting the code.

Collision Detection: Uses color-based detection and bit-testing against alien/barrier arrays.

Randomness: Alien shots are generated using the BIOS timer ticks at address 0046Ch.

📝 License
This project is open-source. Feel free to use, modify, and learn from it.
