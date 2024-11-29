# Simpel script installer arch linux dengan dialog box

<img src="img/imgmain.png" alt="main" width="100%"/>
<img src="img/imgdm.png" alt="diskmanager" width="100%"/>
<img src="img/imgtz.png" alt="timezone" width="100%"/>
<img src="img/imgcon.png" alt="confirm" width="100%"/>

>**Install**

```bash
pacman -Sy && pacman -S git
```

```bash
git clone https://github.com/matobodol/arch-simpel.git
```

```bash
cd arch-simpel
```

```bash
chmod +x *.sh
```

```bash
./install.sh
```

Setelah sukses install, reboot system kemudian login dan aktifkan networkmanager dengan perintah:
```bash
  systemctl enable NetworkManager
  systemctl start NetworkManager
```
