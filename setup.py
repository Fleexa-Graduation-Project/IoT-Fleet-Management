"""
setup.py — packaging for the Fleexa IoT device simulators.

This packages the code under devices/ (the sensor/actuator simulators that
orchestrator.py drives) so it can optionally be installed as a library, e.g.
for use in other tooling or notebooks. It does not package or install the
Go backend, the Flutter mobile app, or the Terraform infrastructure — none
of that is Python.

Project metadata mirrors pyproject.toml; keep the two in sync.
"""
from setuptools import setup, find_packages

setup(
    name="fleexa-iot-simulators",
    version="0.1.0",
    description=(
        "Python device simulators for the Fleexa IoT Fleet Management "
        "platform (temperature, gas, door, and light sensors; door and "
        "AC/curtain actuators)."
    ),
    author="Fleexa Graduation Project",
    license="MIT",
    packages=find_packages(
        include=["devices", "devices.*"],
        exclude=["devices.tests", "devices.tests.*"],
    ),
    python_requires=">=3.11",
    install_requires=[
        "paho-mqtt==2.1.0",
        "jsonschema==4.26.0",
        "python-dateutil==2.9.0.post0",
        "boto3==1.42.50",
        "PyYAML==6.0.2",
        "typing-extensions==4.13.2",
    ],
)
