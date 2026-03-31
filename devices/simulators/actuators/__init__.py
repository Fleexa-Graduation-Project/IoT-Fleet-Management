"""Actuator package exports.

If concrete actuator classes are not implemented yet, dummy placeholders are
exposed to keep imports stable during incremental development.
"""

try:
	from .door_locker import DoorLocker
except Exception:  # pragma: no cover - placeholder fallback
	class DoorLocker:  # type: ignore[no-redef]
		"""Dummy placeholder until door locker implementation exists."""


try:
	from .ac_curtain_actuator import ACCurtainActuator
except Exception:  # pragma: no cover - placeholder fallback
	class ACCurtainActuator:  # type: ignore[no-redef]
		"""Dummy placeholder until AC curtain actuator implementation exists."""


__all__ = [
	"DoorLocker",
	"ACCurtainActuator",
]
