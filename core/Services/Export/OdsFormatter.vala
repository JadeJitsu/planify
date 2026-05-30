/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Services.Export.OdsFormatter : GLib.Object {

    public string build_content_xml_for_test (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        return build_content_xml (rows);
    }

    public async bool format_to_file (Gee.ArrayList<Services.Export.ExportRow?> rows,
                                       string output_path)
    {
        string content_xml  = build_content_xml (rows);
        string manifest_xml = build_manifest_xml ();
        string mimetype     = "application/vnd.oasis.opendocument.spreadsheet";

        string python_script =
            "import zipfile, sys\n" +
            "out, mime, manifest, content = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]\n" +
            "with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:\n" +
            "    zi = zipfile.ZipInfo('mimetype')\n" +
            "    zi.compress_type = zipfile.ZIP_STORED\n" +
            "    z.writestr(zi, mime)\n" +
            "    z.writestr('META-INF/manifest.xml', manifest)\n" +
            "    z.writestr('content.xml', content)\n";

        try {
            string[] argv = {
                "python3", "-c", python_script,
                output_path, mimetype, manifest_xml, content_xml
            };
            var proc = new GLib.Subprocess.newv (argv,
                GLib.SubprocessFlags.STDOUT_PIPE | GLib.SubprocessFlags.STDERR_PIPE);
            string? stdout_out = null;
            string? stderr_out = null;
            yield proc.communicate_utf8_async (null, null, out stdout_out, out stderr_out);
            bool ok = proc.get_successful ();
            if (!ok) {
                Services.LogService.get_default ().error (
                    "OdsFormatter",
                    "python3 ZIP assembly failed: " + (stderr_out ?? "unknown error")
                );
            }
            return ok;
        } catch (Error e) {
            Services.LogService.get_default ().error ("OdsFormatter", e.message);
            return false;
        }
    }

    private string build_content_xml (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        var sb = new GLib.StringBuilder ();
        sb.append ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        sb.append ("<office:document-content\n");
        sb.append ("  xmlns:office=\"urn:oasis:names:tc:opendocument:xmlns:office:1.0\"\n");
        sb.append ("  xmlns:table=\"urn:oasis:names:tc:opendocument:xmlns:table:1.0\"\n");
        sb.append ("  xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\"\n");
        sb.append ("  office:version=\"1.3\">\n");
        sb.append ("<office:body><office:spreadsheet>\n");
        sb.append ("<table:table table:name=\"Tasks\">\n");

        append_data_row (sb, new string[] {
            "Project", "Section", "Task", "Notes", "Due Date", "Priority", "Labels", "Completed"
        });

        foreach (var row in rows) {
            if (row == null) continue;
            var item = row.item;
            append_data_row (sb, new string[] {
                row.project_name,
                row.section_name,
                item.content,
                item.description,
                item.due.date,
                Services.Export.CsvFormatter.priority_to_label (item.priority),
                Services.Export.CsvFormatter.build_labels_string (item),
                item.checked ? "true" : "false"
            });
        }

        sb.append ("</table:table>\n");
        sb.append ("</office:spreadsheet></office:body>\n");
        sb.append ("</office:document-content>\n");
        return sb.str;
    }

    private void append_data_row (GLib.StringBuilder sb, string[] cells) {
        sb.append ("<table:table-row>\n");
        foreach (string cell in cells) {
            sb.append ("<table:table-cell office:value-type=\"string\"><text:p>");
            sb.append (Services.Export.CsvFormatter.escape_xml (cell));
            sb.append ("</text:p></table:table-cell>\n");
        }
        sb.append ("</table:table-row>\n");
    }

    private string build_manifest_xml () {
        return
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<manifest:manifest\n" +
            "  xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\"\n" +
            "  manifest:version=\"1.3\">\n" +
            "<manifest:file-entry manifest:full-path=\"/\"\n" +
            "  manifest:media-type=\"application/vnd.oasis.opendocument.spreadsheet\"/>\n" +
            "<manifest:file-entry manifest:full-path=\"content.xml\"\n" +
            "  manifest:media-type=\"text/xml\"/>\n" +
            "</manifest:manifest>\n";
    }
}
