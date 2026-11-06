from datetime import datetime,timedelta,timezone
from pathlib import Path
from cryptography import x509
from cryptography.hazmat.primitives import hashes,serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID

out=Path(__file__).resolve().parents[3]/'.artifacts/unified-egress';out.mkdir(parents=True,exist_ok=True)
key=rsa.generate_private_key(public_exponent=65537,key_size=2048)
name=x509.Name([x509.NameAttribute(NameOID.COMMON_NAME,'OpenMeeting isolated acceptance CA')])
now=datetime.now(timezone.utc)
cert=(x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
 .serial_number(x509.random_serial_number()).not_valid_before(now-timedelta(minutes=5)).not_valid_after(now+timedelta(days=2))
 .add_extension(x509.BasicConstraints(ca=True,path_length=None),True)
 .add_extension(x509.SubjectAlternativeName([x509.DNSName(x) for x in ['vendor','fixture-bucket.vendor']]),False)
 .sign(key,hashes.SHA256()))
(out/'vendor-cert.pem').write_bytes(cert.public_bytes(serialization.Encoding.PEM))
(out/'vendor-key.pem').write_bytes(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
print('Isolated vendor certificate generated; TLS verification remains enabled.')
