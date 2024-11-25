sudo apt install python3.12-venv

python3 -m venv myenv

source myenv/bin/activate

pip install python-dotenv

python3 send_mail.py "mensaje haver si funciona"

deactivate

