import os
from dotenv import load_dotenv
from email.message import EmailMessage
import ssl
import smtplib

load_dotenv()

mail = os.getenv("MAIL")
password = os.getenv("PASSWORD")

subject = "Asunto del email"
body = """
  Contenido del correo...
"""

em = EmailMessage{}
em["From"] = mail
em["To"] = mail
em["Subject"] = subject
em.set_content(body)

context = ssl.create_default_context()

with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as smtp:
  smtp.login(mail, password)
  smtp.sendmail(mail, mail, em.as_string())

