#!/usr/bin/env python3

import sys
import io
import requests

if len(sys.argv) < 1:
    print("usage: ./render_flat_stylesheet.py FILE")
    exit(1)


class StylesheetElement():
    def render(self):
        pass


class ImportRule():
    def __init__(self, url):
        self.url = url

    def render(self):
        return f"@import url({self.url})"


class EverythingElseRule():
    def __init__(self, content):
        self.content = content

    def render(self):
        return self.content


class StylesheetReader():
    def parse(self, filename):
        semantics = []
        css = io.StringIO(self._load(filename))
        for token in self._tokenize(css):
            semantics.append(token)

        return semantics

    def flatten(self, semantics):
        out = []
        for el in semantics:
            if isinstance(el, ImportRule):
                out = self.parse(el.url) + out
            else:
                out.append(el)
        
        external = 0
        for el in semantics:
            if isinstance(el, ImportRule):
                external += 1

        if 0 < external:
            return self.flatten(out)
        else:
            return out

    def render(self, semantics):
        out = ""
        for el in semantics:
            out += el.render()

        return out

    def read(self, res):
        return iter(lambda: res.read(1), "")

    def _tokenize(self, css):
        for cur in self.read(css):
            css.seek(css.tell() - 1)
            if cur == "@":
                yield self._tokenize_read_directive(css)
            else:
                yield self._tokenize_read_declative(css)

    def _tokenize_read_directive(self, css):
        css.seek(css.tell() + 1)
        word = self._tokenize_read_word(css)
        if word == "import":
            url = self._tokenize_read_property_url(css)
            return ImportRule(url)

        elif word == "media":
            buf = "@media"
            buf += self._tokenize_read_declative_selector(css)
            buf += self._tokenize_read_declative_block(css)
            return EverythingElseRule(buf)

        elif word == "font-face":
            buf = "@font-face"
            buf += self._tokenize_read_declative_block(css)
            return EverythingElseRule(buf)
            
        else:
            return EverythingElseRule("<wel, this is akward.>")


            
    def _tokenize_read_declative(self, css):
        buf = ""
        buf += self._tokenize_read_declative_selector(css)
        buf += self._tokenize_read_declative_block(css)

        return EverythingElseRule(buf)

    def _tokenize_read_declative_selector(self, css):
        buf = ""
        for cur in self.read(css):
            if cur == "{":
                css.seek(css.tell() - 1)
                break

            buf += cur

        return buf


    def _tokenize_read_declative_block(self, css):
        buf = ""
        scope = 0
        for cur in self.read(css):
            if cur == "{":
                scope += 1

            if cur == "}":
                scope -= 1 


            buf += cur

            if scope == 0:
                break

        return buf

    def _tokenize_read_property_url(self, css):
        url = self._tokenize_read_property(css).split("(")[1]
        return url[:-1]

    def _tokenize_read_property(self, css):
        buf = ""
        for cur in self.read(css):
            if cur == ';':
                break

            buf += cur

        return buf


    def _tokenize_read_word(self, css):
        buf = ""
        for cur in self.read(css):
            if not (cur.isalnum() or cur == '-'):
                css.seek(css.tell() - 1)
                break

            buf += cur

        return buf


    def _syntax(self):
        return 1



    def _load(self, filename):
        contents = ""
        file = None

        if filename[:5] == "https":
            response = requests.get(filename)
            file = io.StringIO(response.text)
        else:
            file = open(filename, "r")

        # Preprocessor: Remove everything unnecessary
        buf = ""
        b_newline = False
        b_comment = False
        lb = file.read(1);
        for cur in iter(lambda: file.read(1), ""):
            if lb == '\n':
                b_newline = True
            if b_newline:
                if cur == " " or cur == "\t":
                    continue
                else:
                    b_newline = False
                    lb = cur
                    continue

            if lb == '/'  and cur == '*':
                b_comment = True
            if lb == '*'  and cur == '/':
                file.seek(file.tell())
                b_comment = False
                cur = file.read(1)
                lb = cur
                continue

            if b_comment:
                lb = cur
                continue

            buf += lb

            if lb == ';':
                contents += buf
                buf = ""

            lb = cur

        contents += buf
        file.close()

        return contents


reader = StylesheetReader()
semantics = reader.parse(sys.argv[1])
print(reader.render(reader.flatten(semantics)))
