#!/usr/bin/env node
// Spawn a pi subagent and return its final response

const { spawn } = require("child_process");

const args = process.argv.slice(2);
let prompt = "";
let model = "";
let thinking = "";
let cwd = "";

for (let i = 0; i < args.length; i++) {
    if (args[i] === "--model" && i + 1 < args.length) {
        model = `--model ${args[i + 1]}`;
        i++;
    } else if (args[i] === "--thinking" && i + 1 < args.length) {
        thinking = `--thinking ${args[i + 1]}`;
        i++;
    } else if (args[i] === "--cwd" && i + 1 < args.length) {
        cwd = `--cwd ${args[i + 1]}`;
        i++;
    } else {
        prompt = args[i];
    }
}

if (!prompt) {
    console.error("Usage: subagent.js <prompt> [--model <model>] [--thinking <level>] [--cwd <dir>]");
    process.exit(1);
}

const piCmd = `pi --mode rpc --no-session ${model} ${thinking} ${cwd}`;
const pi = spawn(piCmd, { shell: true, stdio: ["pipe", "pipe", "pipe"] });

let buffer = "";
let state = "prompt"; // prompt -> wait_end -> done

// Send prompt
pi.stdin.write(JSON.stringify({ type: "prompt", message: prompt }) + "\n");

pi.stdout.on("data", (data) => {
    buffer += data.toString();
    
    const lines = buffer.split("\n");
    buffer = lines.pop() || "";
    
    for (const line of lines) {
        if (!line.trim()) continue;
        
        try {
            const json = JSON.parse(line);
            
            if (state === "prompt" && json.type === "response" && json.command === "prompt" && json.success) {
                state = "wait_end";
            } else if (state === "wait_end" && json.type === "agent_end") {
                // Extract text from last assistant message
                const messages = json.messages || [];
                const lastMsg = messages[messages.length - 1];
                if (lastMsg && lastMsg.role === "assistant") {
                    const textContent = lastMsg.content?.find(c => c.type === "text");
                    const text = textContent?.text || "";
                    console.log(text);
                } else {
                    console.log("");
                }
                pi.kill();
                process.exit(0);
            }
        } catch (e) {
            // Ignore parse errors
        }
    }
});

pi.stderr.on("data", (data) => {
    // Ignore stderr
});

pi.on("close", (code) => {
    process.exit(code || 0);
});

// Timeout after 2 minutes
setTimeout(() => {
    console.error("Timeout");
    pi.kill();
    process.exit(1);
}, 120000);
