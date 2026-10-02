import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"


class RepositoryFoundationTests(unittest.TestCase):
    def test_project_entrypoint_and_autoloads_exist(self):
        project_text = (GAME / "project.godot").read_text(encoding="utf-8")
        self.assertIn('run/main_scene="res://scenes/ui/main_menu.tscn"', project_text)
        for script_path in re.findall(r'"\*res://([^"]+\.gd)"', project_text):
            self.assertTrue((GAME / script_path).is_file(), script_path)

    def test_gameplay_input_actions_are_declared(self):
        project_text = (GAME / "project.godot").read_text(encoding="utf-8")
        for action in ("move_left", "move_right", "move_up", "move_down", "attack", "interact", "pause"):
            self.assertRegex(project_text, rf"(?m)^{action}=\{{")

    def test_scene_script_and_resource_references_exist(self):
        for scene in GAME.rglob("*.tscn"):
            content = scene.read_text(encoding="utf-8")
            for resource_path in re.findall(r'path="res://([^"]+)"', content):
                self.assertTrue((GAME / resource_path).is_file(), f"{scene}: {resource_path}")

    def test_required_agent_documentation_is_present(self):
        required = (
            "ARCHITECTURE.md",
            "GAME_DESIGN.md",
            "WORLD.md",
            "CHARACTERS.md",
            "COMBAT.md",
            "MULTIPLAYER.md",
            "SAVE_SYSTEM.md",
            "HOUSING.md",
            "VEHICLES.md",
            "RADIO.md",
            "MODDING.md",
            "SECURITY.md",
            "BUILDING.md",
            "ANDROID.md",
            "CONTRIBUTING.md",
            "ROADMAP.md",
            "AI_DEVELOPMENT.md",
        )
        for document in required:
            with self.subTest(document=document):
                self.assertTrue((ROOT / "docs" / document).is_file())

    def test_godot_runtime_test_exists(self):
        self.assertTrue((GAME / "tests" / "runtime_smoke_test.gd").is_file())


if __name__ == "__main__":
    unittest.main()
