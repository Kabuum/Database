import hashlib
import os
from pathlib import Path
from urllib.request import urlopen
import zipfile


DATA_DIR = Path("bj_data")
RELEASE_URL = "https://github.com/astep-aau/data/releases/download/v1.0.0"
CHECKSUMS = {
    "map.zip": "b907f2ed30e97631d4094973b80dbd6e5232ed2959b7cfcd66de746246367a80",
    "traj_train_20.csv": "344e9228cc795bf0574a6efd71d0a4169d38493519261bf0f584d6a167944b2e",
    "traj_train_40.csv": "8674243e521c00d5f1abaa022371344b04caab2da925251b80b4cb7768d5c02b",
    "traj_train_60.csv": "fb527d53ade3b137e05b3c86a4ede557392b13077fb5de95cc9d7a88e598ec25",
    "traj_train_80.csv": "791098d000a669333b5258581d154698f8fcebc930fdd7c439fc9b13dad72fa8",
    "traj_train_100.csv": "f3fa81b87fcbd0804e51f71bcf56cb2182433cc7ab4a96abb3b49214e542b82b",
    "traj_valid.csv": "aa8da7768d80ab3b72da2729f4fd73b24f4f1862c9df161d0740b32a7efa0387",
    "traj_test.csv": "2286d1933f6f84a6f49f1584e3b968eef7841d068afdfab770f2f64fd41dcbe6",
}


def checksum(path):
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_data():
    DATA_DIR.mkdir(exist_ok=True)
    for name, expected in CHECKSUMS.items():
        path = DATA_DIR / name
        if path.exists() and checksum(path) == expected:
            continue
        print(f"Downloading {name}...", flush=True)
        temporary = path.with_suffix(path.suffix + ".part")
        try:
            with urlopen(f"{RELEASE_URL}/{name}") as response, temporary.open("wb") as file:
                while chunk := response.read(1024 * 1024):
                    file.write(chunk)
            if checksum(temporary) != expected:
                raise ValueError(f"Checksum mismatch for {name}")
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)

    print("Extracting map...")
    with zipfile.ZipFile(DATA_DIR / "map.zip") as archive:
        archive.extractall(DATA_DIR)
