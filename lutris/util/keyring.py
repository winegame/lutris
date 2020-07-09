# Third Party Libraries
import keyring
from keyring.errors import PasswordSetError

KEYRING_NAME = "??"


def store_credentials(username, password):
    try:
        keyring.set_password("WineGame", username, password)
        return True
    except PasswordSetError:
        return False
