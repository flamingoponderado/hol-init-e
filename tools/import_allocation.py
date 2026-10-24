#!/usr/bin/env python3
"""Import literal Lean register colourings as untrusted HOL compiler hints.

Only list/option/sptree constructors and natural literals are accepted. No Lean
proof is imported; from_word_0_riscv validates all colourings in the HOL kernel.
"""
import argparse
from pathlib import Path
import re

TOKEN = re.compile(r"Flapjack\.Spt\.(?:ln|ls|bn|bs)|some|none|[0-9]+|[()[\],]|\s+")

def encode(source):
    body = source.split(":=", 1)[1].split("theorem", 1)[0].strip()
    tokens, position = [], 0
    for match in TOKEN.finditer(body):
        if match.start() != position:
            raise ValueError("unsupported allocation syntax: " + body[position:position+60])
        position = match.end()
        if not match.group().isspace(): tokens.append(match.group())
    if position != len(body): raise ValueError("unparsed allocation suffix")
    index = 0
    def take(expected=None):
        nonlocal index
        if index == len(tokens): raise ValueError("truncated allocation")
        value = tokens[index]; index += 1
        if expected is not None and value != expected:
            raise ValueError("expected " + expected + ", found " + value)
        return value
    def number():
        value = take()
        if not value.isdigit(): raise ValueError("expected natural literal")
        return value
    def tree():
        token = take()
        if token == "(":
            result = tree(); take(")"); return result
        if token == "Flapjack.Spt.ln": return ["Ln"]
        if token == "Flapjack.Spt.ls": return ["Ls", number()]
        if token == "Flapjack.Spt.bn":
            left = tree(); right = tree(); return ["Bn", *left, *right]
        if token == "Flapjack.Spt.bs":
            left = tree(); value = number(); right = tree()
            return ["Bs", *left, value, *right]
        raise ValueError("unsupported tree constructor: " + token)
    result = []
    take("[")
    while tokens[index] != "]":
        option = take()
        if option == "none": result.append(["N"])
        elif option == "some": result.append(["S", *tree()])
        else: raise ValueError("expected allocation option")
        if tokens[index] == ",": take(",")
        elif tokens[index] != "]": raise ValueError("missing entry separator")
    take("]")
    if index != len(tokens): raise ValueError("trailing allocation tokens")
    return result

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("source", type=Path, help="pinned AllocationOracles chunk directory")
    p.add_argument("output", type=Path)
    p.add_argument("--expected-count", type=int, required=True)
    args = p.parse_args()
    chunks = sorted(args.source.glob("Chunk[0-9][0-9][0-9].lean"))
    if not chunks or [x.name for x in chunks] != [f"Chunk{i:03}.lean" for i in range(len(chunks))]:
        raise ValueError("noncontiguous allocation chunks")
    entries = [entry for chunk in chunks for entry in encode(chunk.read_text())]
    if len(entries) != args.expected_count: raise ValueError("allocation count differs")
    args.output.write_text("\n".join(line for entry in entries for line in entry)+"\nE\n")
    print("Imported", len(entries), "untrusted allocation hints")

if __name__ == "__main__": main()
