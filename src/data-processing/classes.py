from __future__ import annotations
from pydantic import BaseModel, Field
from typing import TypedDict


class Coder(TypedDict):
    email: str
    name: str
    annotations: list[Annotation]
    #id: int

# class Annotation_value(TypedDict):
#     code: str
#     value: int

class Annotation (BaseModel):
    value: float
    jobid: int
    unit_id: str
    topic: str
    text: str
    coder_name: str