import discord
from discord.ext import commands
import os
import tempfile
import subprocess
import aiohttp
from openai import OpenAI
import psycopg2
from psycopg2.extras import RealDictCursor

print("=== BOT STARTING ===")

# =======================
# ENV CHECK
# =======================
DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
DATABASE_URL = os.getenv("DATABASE_URL")

if not DISCORD_TOKEN:
    print("FATAL: DISCORD_TOKEN not found")
    exit(1)

print("DISCORD_TOKEN OK")

# =======================
# DATABASE
# =======================
def get_db_connection():
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)

def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS dm_users (
                user_id BIGINT PRIMARY KEY,
                username TEXT
            )
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("Database initialized")
    except Exception as e:
        print("Database error:", e)

if DATABASE_URL:
    init_db()
else:
    print("DATABASE_URL not set, skipping DB")

# =======================
# DISCORD BOT
# =======================
intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(
    command_prefix=".",
    intents=intents,
    help_command=None
)

# =======================
# OPENAI
# =======================
client = OpenAI(
    api_key=os.getenv("AI_INTEGRATIONS_OPENAI_API_KEY"),
    base_url=os.getenv("AI_INTEGRATIONS_OPENAI_BASE_URL")
)

WATERMARK = """-- // FlameCoder V6
-- // Discord:https://discord.gg/5fDu6ymSAf
"""

# =======================
# EVENTS
# =======================
@bot.event
async def on_ready():
    print(f"BOT ONLINE: {bot.user}")
    await bot.change_presence(
        activity=discord.Activity(
            type=discord.ActivityType.watching,
            name=".help_obf | DM!!"
        )
    )

@bot.event
async def on_message(message):
    if message.author.bot:
        return

    if isinstance(message.channel, discord.DMChannel) and DATABASE_URL:
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(
                """
                INSERT INTO dm_users (user_id, username)
                VALUES (%s, %s)
                ON CONFLICT (user_id)
                DO UPDATE SET username = EXCLUDED.username
                """,
                (message.author.id, message.author.name)
            )
            conn.commit()
            cur.close()
            conn.close()
        except Exception as e:
            print("DM log error:", e)

    await bot.process_commands(message)

# =======================
# COMMANDS
# =======================
@bot.command()
async def ping(ctx):
    await ctx.send(f"Pong! {round(bot.latency * 1000)}ms")

@bot.command(name="help_obf")
async def help_obf(ctx):
    embed = discord.Embed(
        title="FlameCoder V6 Obfuscator",
        color=discord.Color.orange()
    )
    embed.add_field(
        name="How to use",
        value="Upload .lua / .txt lalu ketik `.obfuscate`",
        inline=False
    )
    await ctx.send(embed=embed)

@bot.command()
async def ai(ctx, *, prompt: str):
    async with ctx.typing():
        try:
            res = client.chat.completions.create(
                model="gpt-4o",
                messages=[{"role": "user", "content": prompt}]
            )
            await ctx.send(res.choices[0].message.content[:2000])
        except Exception as e:
            await ctx.send(f"AI error: {e}")

@bot.command()
async def obfuscate(ctx):
    if not ctx.message.attachments:
        await ctx.send("Attach file .lua / .txt")
        return

    for att in ctx.message.attachments:
        if not att.filename.endswith((".lua", ".txt")):
            continue

        data = await att.read()
        await ctx.send("Processing...")

        with tempfile.NamedTemporaryFile(delete=False, suffix=".lua") as f:
            f.write(data)
            inp = f.name

        out = inp + "_obf.lua"

        try:
            cmd = f"luajit cli.lua --preset Medium --out {out} {inp}"
            proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)

            if proc.returncode != 0:
                await ctx.send(f"Error:\n```{proc.stderr}```")
                return

            with open(out, "r") as f:
                content = WATERMARK + "\n" + f.read()

            with open(out, "w") as f:
                f.write(content)

            await ctx.send(file=discord.File(out, filename=f"obf_{att.filename}"))

        except Exception as e:
            await ctx.send(f"Obfuscate error: {e}")
        finally:
            if os.path.exists(inp): os.remove(inp)
            if os.path.exists(out): os.remove(out)

# =======================
# START BOT
# =======================
print("Starting Discord bot...")
bot.run(DISCORD_TOKEN)
