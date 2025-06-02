# Chrome Dino FPGA

https://github.com/user-attachments/assets/b39998a3-acd0-43fd-8543-f5f1fd47a893

A full hardware recreation of the Chrome dino game, built as my final project for Digital Logic & Computer Design at UNC-CH.
The game runs on a MIPS CPU we coded from scratch in SystemVerilog, synthesized to a Digilent Nexys A7 (Artix-7) board.
The game uses keyboard input, VGA output, and simple PWM audio.


---

## Cool Stuff
- MIPS CPU written in SystemVerilog  
- Game logic written in MIPS assembly (with a desktop C prototype)  
- VGA @ 640 × 480 with hardware sprite blitting 
- PS/2 keyboard controls (space/↑ to jump, ↓ to duck)  
- Simple PWM audio for jump / collision sounds  

---

## Repo structure

| Path            | What’s inside                                                                                   |
| --------------- | ----------------------------------------------------------------------------------------------- |
| **`asm/`**      | MIPS assembly source for the on-board CPU                                                       |
| **`hardware/`** | SystemVerilog top module, VGA controller, keyboard interface, constraint (.xdc) files           |
| **`host/`**     | Pure-C “template” version of the game that runs on a PC for logic prototyping / debugging       |
| **`mem/`**      | Memory initialization files for instruction, data, sprite  memory regions used by the CPU       |
| **`sprites/`**  | Sprite text files (dino, cactus, ground, etc) and Python helpers for sprite/audio preprocessing |



## Controls on hardware

| Action | Key              | Notes                                   |
| ------ | ---------------- | --------------------------------------- |
| Jump   | **↑**            | Rising-edge detected via PS/2 scan-code |
| Duck   | **↓**            | Lowers dino hitbox                      |
| Reset  | **BTN0** (board) | Reloads RAM, restarts score             |

---


