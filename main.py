from fastapi import FastAPI
import re

app = FastAPI()

VERSION=1
URL_PREFIX=f'/v{VERSION}/urlinfo/'

print(f"[DEBUG] Using URL_PREFIX: {URL_PREFIX}")

@app.get(URL_PREFIX + '{url:path}')
async def url_check(url: str):
    result = {
        'safe': True,
    }  # default to true, unless we match an unsafe criteria
    test_pattern = 'http.*'
    matches = re.match('http[s]?.*www.youtube.com/shorts/.*', url)
    if matches:
        print("Matched a youtube shorts URL; unsafe!")
        result['safe'] = False

    if not db_lookup_url(url):
        result['safe'] = False

    return result

async def db_lookup_url(url: str):
    # To-do: Database lookups to see if we find a matching malware URL
    print("[WARNING] Database lookups not implemented; assuming safe")
    return True