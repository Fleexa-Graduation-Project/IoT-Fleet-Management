"""Sensor package exports.

If concrete sensor classes are not implemented yet, dummy placeholders are
exposed to keep imports stable during incremental development.
"""

try:
	from .temperature_sensor import TemperatureSensor
except Exception:  # pragma: no cover - placeholder fallback
	class TemperatureSensor:  # type: ignore[no-redef]
		"""Dummy placeholder until temperature sensor implementation exists."""


try:
	from .light_sensor import LightSensor
except Exception:  # pragma: no cover - placeholder fallback
	class LightSensor:  # type: ignore[no-redef]
		"""Dummy placeholder until light sensor implementation exists."""


try:
	from .gas_sensor import GasSensor
except Exception:  # pragma: no cover - placeholder fallback
	class GasSensor:  # type: ignore[no-redef]
		"""Dummy placeholder until gas sensor implementation exists."""


try:
	from .door_sensor import DoorSensor
except Exception:  # pragma: no cover - placeholder fallback
	class DoorSensor:  # type: ignore[no-redef]
		"""Dummy placeholder until door sensor implementation exists."""


__all__ = [
	"TemperatureSensor",
	"LightSensor",
	"GasSensor",
	"DoorSensor",
]
