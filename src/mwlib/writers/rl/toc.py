#! /usr/bin/env python

# Copyright (c) 2007, 2008, 2009 PediaPress GmbH
# See README.txt for additional licensing information.

import logging
log = logging.getLogger("mwlib.serve")

import os
import shutil
import subprocess
from gettext import gettext as _

from reportlab.platypus.doctemplate import SimpleDocTemplate
from reportlab.platypus.paragraph import Paragraph
from reportlab.platypus.tables import Table, TableStyle  # ensure TableStyle imported if needed

from mwlib.writers.rl import fontconfig, pdfstyles


class TocRenderer:
    def __init__(self):
        font_switcher = fontconfig.RLFontSwitcher()
        font_switcher.font_paths = fontconfig.font_paths
        font_switcher.register_default_font(pdfstyles.DEFAULT_FONT)
        font_switcher.register_font_def_list(fontconfig.fonts)
        font_switcher.register_reportlab_fonts(fontconfig.fonts)

    def build(self, pdfpath, toc_entries, has_title_page=False, rtl=False):
        outpath = os.path.dirname(pdfpath)
        tocpath = os.path.join(outpath, "toc.pdf")
        finalpath = os.path.join(outpath, "final.pdf")
        self.render_toc(tocpath, toc_entries, rtl=rtl)
        return self.combine_pdfs(pdfpath, tocpath, finalpath, has_title_page)

    def _get_col_widths(self):
        """
        Return safe [title_col_width, page_col_width].

        Original logic could yield 0 or negative width for the title column
        when the page number sample width ~= PRINT_WIDTH (or rounding).
        """
        # Measure a sample page number with a realistic wrapping width
        sample_para = Paragraph(
            "<b>9999</b>",
            pdfstyles.text_style(mode="toc_article", text_align="right"),
        )
        # Wrap with full printable width so we get intrinsic width of the short sample
        sample_w, _ = sample_para.wrap(pdfstyles.PRINT_WIDTH, pdfstyles.PRINT_HEIGHT)

        PRINT_W = pdfstyles.PRINT_WIDTH
        GAP = 30          # existing heuristic gap
        MIN_TITLE = 80    # ensure room for text (>= padding + content)
        MIN_PAGE = 30

        # Cap page column to at most 25% of printable width
        page_col = int(min(max(sample_w, MIN_PAGE), PRINT_W * 0.25))
        title_col = PRINT_W - page_col - GAP

        if title_col < MIN_TITLE:
            # Shrink page column to free space
            needed = MIN_TITLE - title_col
            page_col = max(MIN_PAGE, page_col - needed)
            title_col = PRINT_W - page_col - GAP

        # Final clamps
        if title_col < MIN_TITLE:
            title_col = MIN_TITLE
        if page_col < MIN_PAGE:
            page_col = MIN_PAGE

        # If still overflowing, proportionally scale
        total = title_col + page_col + GAP
        if total > PRINT_W:
            scale = (PRINT_W - GAP) / (title_col + page_col)
            title_col = max(MIN_TITLE, int(title_col * scale))
            page_col = max(MIN_PAGE, int(page_col * scale))

        return [title_col, page_col]

    def render_toc(self, tocpath, toc_entries, rtl):
        doc = SimpleDocTemplate(tocpath, pagesize=(pdfstyles.PAGE_WIDTH,
                                                   pdfstyles.PAGE_HEIGHT))
        elements = []
        elements.append(
            Paragraph(
                _("Contents"),
                pdfstyles.heading_style(
                    mode="Chapter",
                    text_align="left" if not rtl else "right"),
            )
        )
        toc_table = []
        styles = []
        col_widths = self._get_col_widths()

        # Safety: ensure no zero/negative after earlier math
        col_widths = [max(40, int(w)) for w in col_widths]

        for row_idx, (lvl, txt, page_num) in enumerate(toc_entries):
            if lvl == "article":
                page_num = str(page_num)
            elif lvl == "Chapter":
                page_num = "<b>%d</b>" % page_num
                styles.append(("TOPPADDING", (0, row_idx), (-1, row_idx), 10))
            elif lvl == "group":
                page_num = " "
                styles.append(("TOPPADDING", (0, row_idx), (-1, row_idx), 10))

            toc_table.append(
                [
                    Paragraph(
                        txt, pdfstyles.text_style(mode="toc_%s" % str(lvl),
                                                  text_align="left")
                    ),
                    Paragraph(
                        page_num, pdfstyles.text_style(mode="toc_article",
                                                       text_align="right")
                    ),
                ]
            )
        table = Table(toc_table, colWidths=col_widths)
        table.setStyle(styles)
        elements.append(table)
        doc.build(elements)

    def run_cmd(self, cmd):
        try:
            log.info("TOC cmd: %r", cmd)
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = proc.communicate()
            rc = proc.returncode
            # Basic metrics
            log.info("TOC rc=%d, stdout_len=%d, stderr_len=%d", rc, len(out or b""), len(err or b""))
            # Detailed output (debug-level to avoid noise)
            if out:
                try:
                    log.debug("TOC stdout:\n%s", out.decode("utf-8", "replace"))
                except Exception:
                    log.debug("TOC stdout (bytes): %r", out)
            if err:
                try:
                    log.debug("TOC stderr:\n%s", err.decode("utf-8", "replace"))
                except Exception:
                    log.debug("TOC stderr (bytes): %r", err)
            return rc
        except OSError as e:
            log.error("TOC command failed to start: %s", e)
            return 1

    def pdftk(self, pdfpath, tocpath, finalpath, has_title_page):
        if shutil.which("pdftk") is None:
            log.error("pdftk not found in PATH")
            return 1
        
        cmd = [
            "pdftk",
            "A=%s" % pdfpath,
            "B=%s" % tocpath,
        ]
        if not has_title_page:
            cmd.extend(["cat", "B", "A"])
        else:
            cmd.extend(["cat", "A1", "B", "A2-end"])
        cmd.extend(["output", finalpath])
        return self.run_cmd(cmd)

    def pdfsam(self, pdfpath, tocpath, finalpath, has_title_page):
        cmd = ["pdfsam-console"]
        if not has_title_page:
            cmd.extend(["-f", tocpath, "-f", pdfpath])
        else:
            cmd.extend(["-f", pdfpath, "-f", tocpath,
                        "-f", pdfpath, "-u", "1-1:all:2-:"])
        cmd.extend(["-o", finalpath, "-overwrite", "concat"])
        return self.run_cmd(cmd)

    def combine_pdfs(self, pdfpath, tocpath, finalpath, has_title_page):
        if os.path.splitext(pdfpath)[1] == ".pdf":
            safe_pdfpath = pdfpath
        else:
            safe_pdfpath = pdfpath + ".pdf"
            shutil.move(pdfpath, safe_pdfpath)
        retcode = self.pdfsam(safe_pdfpath, tocpath,
                              finalpath, has_title_page=has_title_page)
        if retcode != 0:
            retcode = self.pdftk(safe_pdfpath, tocpath, finalpath,
                                 has_title_page=has_title_page)
        if retcode == 0:
            shutil.move(finalpath, pdfpath)
        else:
            if not os.path.exists(pdfpath) and os.path.exists(safe_pdfpath):
                shutil.copy(safe_pdfpath, pdfpath)
        if os.path.exists(tocpath):
            os.unlink(tocpath)
        return retcode

