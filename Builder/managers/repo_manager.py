
import os
import subprocess
import shutil
import tempfile
import traceback
from pathlib import Path
from loguru import logger
from managers.package_manager import PackageManager

class RepoManager:
    """Manager for installing custom repositories"""
    
    REPOS = [
        "https://github.com/meowrch/meowrch-settings",
        "https://github.com/meowrch/meowrch-tools",
        "https://github.com/meowrch/nemo-extensions",
        "https://github.com/meowrch/plymouth-theme",
        "https://github.com/meowrch/mewline",
        "https://github.com/meowrch/HotKeyHub",
        "https://github.com/meowrch/pawlette",
        "https://github.com/meowrch/pawlette-themes",
        "https://github.com/meowrch/pawlette-catppuccin-mocha-theme",
        "https://github.com/meowrch/pawlette-catppuccin-latte-theme",
        "https://github.com/meowrch/rofi-network-manager"
    ]

    @staticmethod
    def install_custom_repos() -> None:
        logger.info("Starting installation of custom Meowrch repositories...")
        
        # Ensure base-devel and git are installed
        PackageManager.install_packages(["base-devel", "git"])
        
        for repo_url in RepoManager.REPOS:
            repo_name = repo_url.split("/")[-1]
            logger.info(f"Processing repository: {repo_name}")
            
            with tempfile.TemporaryDirectory() as temp_dir:
                target_path = Path(temp_dir) / repo_name
                
                if PackageManager.clone_repository(repo_url, str(target_path)):
                    # Check for PKGBUILD
                    pkgbuild_path = target_path / "PKGBUILD"
                    if pkgbuild_path.exists():
                        logger.info(f"Found PKGBUILD in {repo_name}, building package...")
                        try:
                            # Modify PKGBUILD if architecture is x86_64 only
                            RepoManager._patch_pkgbuild_arch(pkgbuild_path)
                            
                            subprocess.run(
                                ["makepkg", "-si", "--noconfirm"], 
                                cwd=str(target_path), 
                                check=True
                            )
                            logger.success(f"{repo_name} installed successfully via makepkg!")
                        except subprocess.CalledProcessError as e:
                            logger.error(f"Failed to build {repo_name}: {e}")
                        except Exception as e:
                            logger.error(f"Error processing {repo_name}: {traceback.format_exc()}")
                    else:
                        # Fallback: Check for install.sh or Makefile
                        RepoManager._install_manual(target_path, repo_name)
                else:
                    logger.error(f"Failed to clone {repo_name}")

    @staticmethod
    def _patch_pkgbuild_arch(pkgbuild_path: Path) -> None:
        """Patches PKGBUILD to support aarch64 if only x86_64 is listed"""
        try:
            with open(pkgbuild_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if "arch=('x86_64')" in content or 'arch=("x86_64")' in content:
                logger.warning(f"Patching architecture in {pkgbuild_path.name} to include aarch64...")
                content = content.replace("arch=('x86_64')", "arch=('x86_64' 'aarch64')")
                content = content.replace('arch=("x86_64")', 'arch=("x86_64" "aarch64")')
                
                with open(pkgbuild_path, 'w', encoding='utf-8') as f:
                    f.write(content)
        except Exception as e:
            logger.warning(f"Could not patch PKGBUILD: {e}")

    @staticmethod
    def _install_manual(path: Path, name: str) -> None:
        """Manual installation fallback"""
        logger.warning(f"No PKGBUILD found for {name}. Checking for manual install scripts...")
        
        # Check for install.sh
        install_sh = path / "install.sh"
        if install_sh.exists():
            try:
                subprocess.run(["chmod", "+x", str(install_sh)], check=True)
                subprocess.run(["bash", str(install_sh)], cwd=str(path), check=True)
                logger.success(f"{name} installed via install.sh")
                return
            except Exception as e:
                logger.error(f"Failed to run install.sh for {name}: {e}")

        # Check for Makefile
        makefile = path / "Makefile"
        if makefile.exists():
            try:
                subprocess.run(["make"], cwd=str(path), check=True)
                subprocess.run(["sudo", "make", "install"], cwd=str(path), check=True)
                logger.success(f"{name} installed via Makefile")
                return
            except Exception as e:
                logger.error(f"Failed to run make for {name}: {e}")
        
        logger.warning(f"No standard installation method found for {name}. You may need to install it manually.")
