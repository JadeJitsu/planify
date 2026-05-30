/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Services.Export.OmniOpmlFormatter : GLib.Object {

    public string format (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        var sb = new GLib.StringBuilder ();
        sb.append ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        sb.append ("<opml version=\"2.0\">\n");
        sb.append ("  <head><title>Planify Export</title></head>\n");
        sb.append ("  <body>\n");

        string current_project = null;
        string current_section = null;

        foreach (var row in rows) {
            if (row == null) continue;

            if (row.project_name != current_project) {
                if (current_section != null && current_section != "") {
                    sb.append ("      </outline>\n");
                }
                if (current_project != null) {
                    sb.append ("    </outline>\n");
                }
                current_project = row.project_name;
                current_section = null;
                sb.append ("    <outline text=\"");
                sb.append (Services.Export.CsvFormatter.escape_xml (current_project));
                sb.append ("\">\n");
            }

            if (row.section_name != current_section) {
                if (current_section != null && current_section != "") {
                    sb.append ("      </outline>\n");
                }
                current_section = row.section_name;
                if (current_section != "") {
                    sb.append ("      <outline text=\"");
                    sb.append (Services.Export.CsvFormatter.escape_xml (current_section));
                    sb.append ("\">\n");
                }
            }

            string indent = (current_section != null && current_section != "") ? "        " : "      ";
            append_item (sb, row.item, indent);
        }

        if (current_section != null && current_section != "") {
            sb.append ("      </outline>\n");
        }
        if (current_project != null) {
            sb.append ("    </outline>\n");
        }

        sb.append ("  </body>\n");
        sb.append ("</opml>\n");
        return sb.str;
    }

    private void append_item (GLib.StringBuilder sb, Objects.Item item, string indent) {
        sb.append (indent);
        sb.append ("<outline text=\"");
        sb.append (Services.Export.CsvFormatter.escape_xml (item.content));
        sb.append ("\"");

        if (item.due.date != "") {
            sb.append (" due=\"");
            sb.append (Services.Export.CsvFormatter.escape_xml (item.due.date));
            sb.append ("\"");
        }
        string plabel = Services.Export.CsvFormatter.priority_to_label (item.priority);
        if (plabel != "") {
            sb.append (" priority=\""); sb.append (plabel); sb.append ("\"");
        }
        if (item.description != "") {
            sb.append (" note=\"");
            sb.append (Services.Export.CsvFormatter.escape_xml (item.description));
            sb.append ("\"");
        }
        if (item.checked) {
            sb.append (" complete=\"true\"");
        }

        if (item.items.size > 0) {
            sb.append (">\n");
            foreach (var sub in item.items) {
                append_item (sb, sub, indent + "  ");
            }
            sb.append (indent); sb.append ("</outline>\n");
        } else {
            sb.append ("/>\n");
        }
    }
}
