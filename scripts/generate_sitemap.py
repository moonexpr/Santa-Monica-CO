#!/usr/bin/env python3

from xml.dom import getDOMImplementation as DOM
from time import sleep, time
import os

PUBLIC_WEBROOT = "https://chandara.keybase.pub"
KBFS_DOCROOT_DEPTH = 4

def get_subfiles(root, path):
    len_prepath = len(root)
    out = []
    print(f"       > {path[len_prepath:]}")
    for file in os.listdir(path):
        subpath = f"{path}/{file}"
        out.append(subpath)

        if os.path.isdir(subpath):
            for subpath in get_subfiles(root, subpath):
                out.append(subpath)

    return out



def get_pubfiles(path):
    print(f" * {path}")
    sleep(1)
    len_prepath = len(path)
    out = []
    print(f"       > /{path[len_prepath:]}")
    for file in os.listdir(path):
        subpath = f"{path}/{file}"
        out.append(PUBLIC_WEBROOT + subpath[len_prepath:])

        if os.path.isdir(subpath):
            for subpath in get_subfiles(path, subpath):
                out.append(PUBLIC_WEBROOT + subpath[len_prepath:])

    return out

def kbfs_rootpath(path):
    dirs = path.split('/')
    for i, name in enumerate(dirs):
        if name == '.':
            dirs = dirs[:i] + dirs[i+1:]
            continue

        if name == 'kbfs' or name == 'keybase':
            return '/'.join(dirs[:i + KBFS_DOCROOT_DEPTH])

    print('sitemap: Script fail!')
    print(f'sitemap: Directory {path} is invalid! make sure you\'re inside the Keybase File System.')
    exit(1)

t_start = time()

D = DOM().createDocument(None, "urlset", None)
path_root = kbfs_rootpath(os.path.dirname(__file__))
path_sitemap = f"{path_root}/sitemap.xml"
pubfiles = get_pubfiles(path_root)


root = D.documentElement
root.setAttribute("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")
root.setAttribute("xmlns:image", "http://www.google.com/schemas/sitemap-image/1.1")
root.setAttribute("xmlns:xhtml", "http://www.w3.org/1999/xhtml")

pi_style = D.createProcessingInstruction("xml-stylesheet", "type=\"text/xsl\" href=\"/resources/sitemap_style.xsl\"")
D.insertBefore(pi_style, D.firstChild)

for public_path in pubfiles:
    url = root.appendChild(D.createElement('url'))
    url.appendChild(D.createElement('loc')) \
        .appendChild(D.createTextNode(public_path))

output = D.toprettyxml(indent = "  ")
with open(path_sitemap, "w") as file:
    file.write(output)

t = round((time() - t_start) * 1000)

output_len = len(output.encode('utf-8'))
print(f"\nsitemap: Successfully finished in {t}ms!")
print(f"sitemap: * Script found {len(pubfiles)} indexable files in total.")
print(f"sitemap: * Script wrote {output_len} bytes to file {path_sitemap}.")
