#!/usr/bin/python3
import os
from dotenv import load_dotenv
from email.message import EmailMessage
import ssl
import smtplib
import sys

load_dotenv()

print(sys.argv, flush=True)

password = os.getenv("PASSWORD_MAIL_KUMA")
mail = os.getenv("MAIL_KUMA")

subject = "Asunto del email"
body = sys.argv

em = EmailMessage()
em["From"] = mail
em["To"] = mail
em["Subject"] = subject
em.set_content(body)

context = ssl.create_default_context()

with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as smtp:
  smtp.login(mail, password)
  smtp.sendmail(mail, mail, em.as_string())
