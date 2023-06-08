#!/usr/bin/env python3

import os
import sys
import traceback

from lxml import etree


header = [
    "date", "tier", "group",
    "title", "id", "href", "host",
    "ipv4", "ipv6",
    "owner", "crtd", "status",
]

def err(msg: str):
    """Logs a message to STDERR"""
    if not msg.endswith("\n"):
        msg += "\n"

    sys.stderr.write(msg)
    sys.stderr.flush()


def log(msg: str):
    """Logs a message to STDOUT"""
    if not msg.endswith("\n"):
        msg += "\n"

    sys.stdout.write(msg)
    sys.stdout.flush()


def get_xpath(node, xpath):
    """Extracts the value form a node and a XPath expression."""
    val = node.xpath(xpath)

    if len(val) == 0:
        return ""
    elif len(val) == 1:
        return val.pop()
    else:
        return val


def to_csv(vals: list, sep=",", quote_char='"') -> str:
    """Converts a list of values to CSV with defined separator and quote_chars"""
    # vals = [f'"{v}"' for v in vals if sep in v else f"{v}"]
    vals = map(
        lambda v: quote_char + f"{str(v)}" + quote_char if sep in str(v) else f"{str(v)}",
        vals,
    )
    # vals = [v.replace("\n", " ").replace("\r", " ") for v in vals]
    vals = [repr(v)[1:-1] for v in vals]
    return f"{sep}".join(vals)


def parse_html_to_values(html: str) -> list:
    """Parses the HTML and extracts the information about the servers"""
    data = []

    # Load file to ElementTree
    tree = etree.HTML(html)
    group_names = tree.xpath("//div[@id='srvlist']/div/@name")

    # Get all group names and add them too
    for group in group_names:
        group_str = group[3:].strip("[]")

        for p in tree.xpath(f"//div[@id='srvlist']/div[@name='{group}']/p"):
            host_title = get_xpath(p, "./span[@class='host']/@title")
            host_id = get_xpath(p, "./span[@class='host']/a/@id")
            host_href = get_xpath(p, "./span[@class='host']/a/@href")
            host_name = get_xpath(p, "./span[@class='host']/a/text()")

            ipv4 = get_xpath(p, "./span[@class='mono ipv4']/text()")
            ipv6 = get_xpath(p, "./span[@class='mono ipv6']/text()")
            owner = get_xpath(p, "./span[@class='ownr']/text()")
            crtd = get_xpath(p, "./span[@class='crtd']/text()")
            stat = get_xpath(p, "./span[@class='stat']/text()")
                
            data.append([
                group_str,
                host_title, host_id, host_href, host_name,
                ipv4, ipv6,
                owner, crtd, stat,
            ])
    
    return data


def main():
    # Parse system arguments
    if len(sys.argv) < 2:
        err(f"Usage: {sys.argv[0]} <FILE>")
        sys.exit(1)

    file_path = sys.argv[1]

    if not os.path.isfile(file_path):
        err("Unknown file path")
        err(f"Usage: {sys.argv[0]} <File>")
        sys.exit(1)

    # Load the HTML
    html = ""

    with open(file_path, "r") as f:
        html = "".join(f.readlines())

    try:
        if "/" in file_path:
            file_path = file_path.split("/")[-1]

        date, tier, _ = file_path.split(".")
        date = date[:4] + "-" + date[4:6] + "-" + date[6:]
        tier = int(tier[4:])

        records = parse_html_to_values(html)

        log(to_csv(header))

        for rec in records:
            log(to_csv([date, tier] + rec))

    
    except Exception as e:
        err(str(e))
        err(traceback.format_exc())


if __name__ == "__main__":
    main()