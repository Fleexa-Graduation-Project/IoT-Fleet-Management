with open('.github/workflows/ci-cd.yml', 'r') as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, line in enumerate(lines):
    if skip:
        if line.strip() == "aws iot list-ca-certificates --region us-east-1 \\":
            skip = False
        if not skip:
            pass # We don't append this exact line yet, we'll append it later, wait actually this is too complex. Let's do it easier.

