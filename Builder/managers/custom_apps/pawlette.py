import ast
import random
import json
import subprocess
import traceback

from loguru import logger
from typing import List

from .base import AppConfigurer


class PawletteConfigurer(AppConfigurer):
    def setup(self) -> None:
        installed_themes = []

        try:
            installed_themes.extend(self._install_available_themes())
        except Exception:
            logger.error(f"Pawlette main setup error: {traceback.format_exc()}")

        if installed_themes:
            if "catppuccin-mocha" in installed_themes:
                apply_theme = "catppuccin-mocha"
            else:
                apply_theme = random.choice(installed_themes)
            
            error_msg = "Error while applying theme {theme_name}: {err}"

            try:
                self._apply_theme(apply_theme)

            except subprocess.CalledProcessError as e:
                logger.error(error_msg.format(theme_name=apply_theme, err=e.stderr))
            except Exception:
                logger.error(
                    error_msg.format(
                        theme_name=apply_theme, err=traceback.format_exc()
                    )
                )

    def _parse_themes(self, raw: str) -> dict:
        """Пытается распарсить вывод разными способами"""
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            logger.warning("Failed JSON parse, trying literal eval")
            try:
                data = ast.literal_eval(raw)
                if isinstance(data, dict):
                    return data
                raise ValueError("Not a dictionary")
            except Exception:
                logger.error("All parsing attempts failed")
                raise

    def _install_available_themes(self) -> List[str]:
        # Themes should already be installed by RepoManager
        # We just verify they are available
        themes = ["catppuccin-mocha", "catppuccin-latte"]
        verified_themes = []
        
        logger.info("Checking for installed pawlette themes...")
        try:
             # Check if themes are listed in pawlette
             result = subprocess.run(
                ["pawlette", "list-themes"],
                capture_output=True,
                text=True
             )
             available = result.stdout
             
             for theme in themes:
                 if theme in available:
                     verified_themes.append(theme)
                 else:
                     logger.warning(f"Theme {theme} is not detected by pawlette (files might be missing or not indexed).")
        except Exception as e:
            logger.error(f"Failed to list pawlette themes: {e}")
            
        return verified_themes

    def _install_theme(self, theme_name: str) -> None:
        # Deprecated: RepoManager installs packages
        pass

    def _apply_theme(self, theme_name: str) -> None:
        """Логика применения темы"""
        logger.info(f"Applying theme: {theme_name}")
        subprocess.run(
            ["pawlette", "apply", theme_name],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        logger.success(f"Theme {theme_name} applied")
