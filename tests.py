from main import url_check, URL_PREFIX
import urllib.parse
import asyncio

## Add unit tests here..

async def test_with(test_url: str, expected: bool):
    expected_response = { safe: expected }
    req_url = urllib.parse.quote_plus(test_url)
    result = await url_check(req_url)
    assert result == expected


async def run_tests():
    quick_tests = [
        ('https://www.youtube.com/shorts/DJHRSER6Mz4', True),
        ('https://www.youtube.com/shorts/DJHRSER6Mz4', False),
        ('https://www.amazon.ca/', True),
        ('https://www.youtube.com/watch?v=dQw4w9WgXcQ', True),
    ]

    for url, safe in quick_tests:
        await test_with(url, safe)


if __name__ == '__main__':
    asyncio.run(run_tests)
