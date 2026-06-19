/** @jsxImportSource jsx-md */

import { readdirSync, readFileSync } from "fs";
import { join } from "path";

import {
  Heading, Paragraph, CodeBlock,
  Bold, Code, Link,
  Badge, Badges, Center, Section, Alert,
  Raw,
} from "readme/src/components";

// ── Dynamic data ──────────────────────────────────────────────────

const ROOT = import.meta.dir;

function countTests(): number {
  const dir = join(ROOT, "test");
  try {
    return readdirSync(dir)
      .filter(f => f.endsWith(".bats"))
      .reduce((count, f) => {
        const content = readFileSync(join(dir, f), "utf-8");
        return count + (content.match(/@test /g) || []).length;
      }, 0);
  } catch { return 0; }
}

function countLints(): number {
  try {
    const miseToml = readFileSync(join(ROOT, "mise.toml"), "utf-8");
    const start = miseToml.indexOf("[_.codebase]");
    if (start === -1) return 0;

    const block = miseToml.slice(start).split("\n");
    const lines: string[] = [];
    for (const [index, line] of block.entries()) {
      if (index > 0 && line.startsWith("[")) break;
      lines.push(line);
    }

    const list = lines.join("\n").match(/lint\s*=\s*\[([\s\S]*?)\]/)?.[1] ?? "";
    return [...list.matchAll(/"([^"]+)"/g)].length;
  } catch { return 0; }
}

const testCount = countTests();
const lintCount = countLints();

// ── Readme ────────────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Raw>{`<img src="logo.jpg" alt="monkeys logo" width="256">\n\n`}</Raw>

      <Heading level={1}>monkeys</Heading>

      <Paragraph>
        <Bold>Media from the command line — images, speech, transcription, and OCR.</Bold>
      </Paragraph>

      <Badges>
        <Badge label="tasks" value="mise" color="7c3aed" href="https://mise.jdx.dev" />
        <Badge label="runtime" value="uv + Python" color="de5fe9" href="https://docs.astral.sh/uv/" />
        <Badge label="tests" value={`${testCount} passing`} color="blue" href="https://bats-core.readthedocs.io" />
        <Badge label="lints" value={`${lintCount}`} color="0ea5e9" />
      </Badges>
    </Center>

    <Section title="Install">
      <CodeBlock lang="bash">{`shiv install monkeys

# Or manually:
git clone https://github.com/KnickKnackLabs/monkeys.git ~/monkeys
cd ~/monkeys && mise trust && mise install
eval "$(mise -C ~/monkeys run -q shell)"`}</CodeBlock>
    </Section>

    <Section title="Usage">
      <CodeBlock lang="bash">{`# Image generation (requires HF_TOKEN)
monkeys generate "a cartoon monkey"
monkeys generate "pixel art sunset" -o sunset.png

# Text-to-speech (local, no token needed)
monkeys speak "Hello world"
monkeys speak "Good morning" --voice af_bella --play

# Audio input + speech-to-text (local, requires ffmpeg + Qwen setup)
monkeys hear:qwen:setup                       # one-time local ASR setup
monkeys listen -o recording.wav               # record microphone audio to a WAV file
monkeys hear recording.wav                    # batch transcript from a complete file
monkeys listen | monkeys hear                 # live microphone audio → streaming text
monkeys hear --prompt-file glossary.txt -     # stdin defaults to streaming transcription

# OCR — extract text and coordinates from images
monkeys ocr screenshot.png                    # JSON with bounding boxes
monkeys ocr screenshot.png --find "Select"    # Filter by substring
monkeys ocr screenshot.png --text-only        # Plain text output`}</CodeBlock>

      <Alert type="NOTE">
        {"OCR runs locally via EasyOCR — no API key needed. First run downloads models (~50MB)."}
      </Alert>
    </Section>

    <Section title="OCR output">
      <Paragraph>
        {"Default output is JSON with bounding box coordinates, useful for automation (e.g. driving a VM via screenshot → OCR → click):"}
      </Paragraph>

      <CodeBlock lang="json">{`[
  {
    "text": "Select",
    "x": 1029, "y": 681, "w": 40, "h": 16,
    "cx": 1049, "cy": 689,
    "confidence": 0.9987
  }
]`}</CodeBlock>

      <Paragraph>
        <Code>cx</Code>{"/"}
        <Code>cy</Code>
        {" are the center of the bounding box — the click target."}
      </Paragraph>
    </Section>

    <Section title="Configuration">
      <Paragraph>
        {"Set "}
        <Code>HF_TOKEN</Code>
        {" for Hugging Face API authentication (image generation only):"}
      </Paragraph>

      <CodeBlock lang="bash">{`export HF_TOKEN="hf_your_token_here"  # https://huggingface.co/settings/tokens`}</CodeBlock>
    </Section>

    <Section title="Validation">
      <CodeBlock lang="bash">{`mise run test
codebase lint "$PWD"
readme build --check
git diff --check`}</CodeBlock>

      <Paragraph>
        {`${testCount} BATS tests. OCR tests use real EasyOCR against a generated fixture image. Codebase runs ${lintCount} convention lints.`}
      </Paragraph>
    </Section>
  </>
);

console.log(readme);
