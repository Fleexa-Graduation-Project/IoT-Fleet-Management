# simulators/schema_validator.py
import json
import logging
from typing import Dict, Any, Optional
from pathlib import Path
import jsonschema
from jsonschema import validate, ValidationError

logger = logging.getLogger(__name__)

class SchemaValidator:
    """
    Validates JSON messages against defined schemas
    
    Schemas:
    - telemetry.schema.json
    - alert.schema.json
    - command.schema.json
    """
    
    def __init__(self, schema_dir: str = "../../backend/docs/mqtt/schemas"):
        """Initialize validator with schema directory"""
        self.schema_dir = Path(__file__).parent / schema_dir
        self.schemas: Dict[str, Dict] = {}
        
        # Load all schemas
        self._load_schemas()
    
    def _load_schemas(self):
        """Load JSON schemas from directory"""
        schema_files = {
            "telemetry": "telemetry.schema.json",
            "alert": "alert.schema.json",
            "command": "command.schema.json"
        }
        
        for schema_name, filename in schema_files.items():
            schema_path = self.schema_dir / filename
            try:
                with open(schema_path, 'r') as f:
                    self.schemas[schema_name] = json.load(f)
                logger.info(f"✅ Loaded schema: {schema_name}")
            except FileNotFoundError:
                logger.warning(f"⚠️  Schema not found: {schema_path}")
            except json.JSONDecodeError as e:
                logger.error(f"❌ Invalid JSON in {filename}: {e}")
    
    def validate_telemetry(self, message: Dict[str, Any]) -> bool:
        """Validate telemetry message against schema"""
        return self._validate(message, "telemetry")
    
    def validate_alert(self, message: Dict[str, Any]) -> bool:
        """Validate alert message against schema"""
        return self._validate(message, "alert")
    
    def validate_command(self, message: Dict[str, Any]) -> bool:
        """Validate command message against schema"""
        return self._validate(message, "command")
    
    def _validate(self, message: Dict[str, Any], schema_name: str) -> bool:
        """
        Internal validation method
        
        Returns:
            True if valid, False otherwise
        """
        if schema_name not in self.schemas:
            logger.error(f"❌ Schema not loaded: {schema_name}")
            return False
        
        try:
            validate(instance=message, schema=self.schemas[schema_name])
            logger.debug(f"✅ Valid {schema_name} message")
            return True
        except ValidationError as e:
            logger.error(f"❌ Schema validation failed ({schema_name}): {e.message}")
            logger.debug(f"   Failed at path: {list(e.absolute_path)}")
            return False
        except Exception as e:
            logger.error(f"❌ Validation error: {e}")
            return False

# Global validator instance
_validator: Optional[SchemaValidator] = None

def get_validator() -> SchemaValidator:
    """Get or create global validator instance"""
    global _validator
    if _validator is None:
        _validator = SchemaValidator()
    return _validator