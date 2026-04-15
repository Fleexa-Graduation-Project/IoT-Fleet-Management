import pytest

@pytest.mark.skip(reason="Not running AWS integration tests in simple local CI yet.")
def test_aws_iot_connection():
    # In a real integration test, we'd attempt connection to the actual AWS IoT Core endpoint.
    pass
