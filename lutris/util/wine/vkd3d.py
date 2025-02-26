import os

from lutris.settings import RUNTIME_DIR
from lutris.util.linux import LINUX_SYSTEM
from lutris.util.wine.dll_manager import DLLManager


class VKD3DManager(DLLManager):
    component = "VKD3D"
    base_dir = os.path.join(RUNTIME_DIR, "vkd3d")
    versions_path = os.path.join(base_dir, "vkd3d_versions.json")
    managed_dlls = ("d3d12", "d3d12core")
    releases_url = "https://hu60.cn/q.php/lutris.release.vkd3d.json"

    def can_enable(self):
        return LINUX_SYSTEM.is_vulkan_supported()
