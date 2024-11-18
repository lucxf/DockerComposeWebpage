echo -e "\033[34mAgregando repositorios de Tailscale...\033[0m"
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

echo -e "\033[34mInstalando Tailscale...\033[0m"
sudo apt-get update
sudo apt-get install tailscale -y

# Connect your machine to your Tailscale network and authenticate in your browser:
echo -e "\033[34mIniciando Tailscale...\033[0m"
sudo tailscale up

# Pedir al usuario que ingrese el número de la copia de seguridad desde la cual restaurar
echo -e "\033[32mConfigura en tu navegador tailscale, está todo correcto?(si/no)\033[0m"
read config_done

echo -e "\033[34mObteniendo IP...\033[0m"
tailscale ip -4

