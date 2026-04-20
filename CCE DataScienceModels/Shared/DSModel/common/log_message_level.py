from enum import Enum

class LogMessageLevel(Enum):
    NONE = 0    # Log no messages
    ERROR = 1   # Error; code is likely to have failed
    WARNING = 2 # Warnings; code will continue
    INFO= 3    # Informative messages; FYI
    DEBUG = 4   # Debug messages; More detail than Info
    TRACE = 5   # Trace messages: Fine-grained trace information
    ALL = 255   # All messages

