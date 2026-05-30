using GLib;

private Gee.ArrayList<Services.Export.ExportRow?> make_rows (
    string project, string section, string task_title, bool completed)
{
    var item = new Objects.Item ();
    item.content = task_title;
    item.checked = completed;
    item.priority = Constants.PRIORITY_4;
    item.description = "";

    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    rows.add (Services.Export.ExportRow () {
        project_name = project,
        section_name = section,
        item = item
    });
    return rows;
}

void test_csv_quote_plain () {
    assert_cmpstr (Services.Export.CsvFormatter.quote ("hello"), CompareOperator.EQ, "\"hello\"");
}

void test_csv_quote_escapes_inner_quote () {
    assert_cmpstr (Services.Export.CsvFormatter.quote ("say \"hi\""), CompareOperator.EQ, "\"say \"\"hi\"\"\"");
}

void test_csv_priority_label_p1 () {
    assert_cmpstr (Services.Export.CsvFormatter.priority_to_label (Constants.PRIORITY_1),
        CompareOperator.EQ, "P1");
}

void test_csv_priority_label_none () {
    assert_cmpstr (Services.Export.CsvFormatter.priority_to_label (Constants.PRIORITY_4),
        CompareOperator.EQ, "");
}

void test_csv_row () {
    var item = new Objects.Item ();
    item.content = "Buy milk";
    item.checked = false;
    item.priority = Constants.PRIORITY_4;
    item.description = "";

    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    rows.add (Services.Export.ExportRow () {
        project_name = "Work",
        section_name = "Inbox",
        item = item
    });

    string result = new Services.Export.CsvFormatter ().format (rows);
    assert (result.contains ("\"Work\""));
    assert (result.contains ("\"Inbox\""));
    assert (result.contains ("\"Buy milk\""));
    assert (result.contains ("\"false\""));
}

void test_csv_has_header () {
    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    string result = new Services.Export.CsvFormatter ().format (rows);
    assert (result.has_prefix ("\"Project\",\"Section\",\"Task\""));
}

void test_ods_content_xml_has_header () {
    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    string xml = new Services.Export.OdsFormatter ().build_content_xml_for_test (rows);
    assert (xml.contains ("Project"));
    assert (xml.contains ("table:table-row"));
}

void test_omni_csv_header () {
    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    string result = new Services.Export.OmniCsvFormatter ().format (rows);
    assert (result.has_prefix ("\"Task Name\",\"Project\""));
}

void test_omni_csv_flagged_p1 () {
    var item = new Objects.Item ();
    item.content = "Urgent";
    item.checked = false;
    item.priority = Constants.PRIORITY_1;
    item.description = "";

    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    rows.add (Services.Export.ExportRow () {
        project_name = "Work", section_name = "", item = item
    });

    string result = new Services.Export.OmniCsvFormatter ().format (rows);
    assert (result.contains ("\"true\""));
}

void test_omni_csv_not_flagged_p4 () {
    var item = new Objects.Item ();
    item.content = "Normal";
    item.checked = false;
    item.priority = Constants.PRIORITY_4;
    item.description = "";

    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    rows.add (Services.Export.ExportRow () {
        project_name = "Work", section_name = "", item = item
    });

    string result = new Services.Export.OmniCsvFormatter ().format (rows);
    // Flagged column must be "false" for a P4 (none) item
    assert (!result.contains ("\"true\""));
}

void test_opml_envelope () {
    var rows = new Gee.ArrayList<Services.Export.ExportRow?> ();
    string result = new Services.Export.OmniOpmlFormatter ().format (rows);
    assert (result.contains ("<opml version=\"2.0\">"));
    assert (result.contains ("</opml>"));
}

void test_opml_task_outline () {
    var rows = make_rows ("Work", "Inbox", "Buy milk", false);
    string result = new Services.Export.OmniOpmlFormatter ().format (rows);
    assert (result.contains ("text=\"Buy milk\""));
    assert (result.contains ("text=\"Work\""));
}

void test_opml_escapes_ampersand () {
    var rows = make_rows ("Me & You", "", "Task & stuff", false);
    string result = new Services.Export.OmniOpmlFormatter ().format (rows);
    assert (result.contains ("Me &amp; You"));
    assert (result.contains ("Task &amp; stuff"));
}

void test_taskpaper_task_line () {
    var rows = make_rows ("Work", "Inbox", "Buy milk", false);
    string result = new Services.Export.OmniTaskPaperFormatter ().format (rows);
    assert (result.contains ("- Buy milk"));
    assert (result.contains ("@context(Inbox)"));
}

void test_taskpaper_done_tag () {
    var rows = make_rows ("Work", "", "Done task", true);
    string result = new Services.Export.OmniTaskPaperFormatter ().format (rows);
    assert (result.contains ("@done("));
}

void test_markdown_unchecked () {
    var rows = make_rows ("Work", "", "Buy milk", false);
    string result = new Services.Export.MarkdownFormatter ().format (rows);
    assert (result.contains ("- [ ] Buy milk"));
}

void test_markdown_checked () {
    var rows = make_rows ("Work", "", "Done task", true);
    string result = new Services.Export.MarkdownFormatter ().format (rows);
    assert (result.contains ("- [x] Done task"));
}

void test_markdown_section_heading () {
    var rows = make_rows ("Work", "Inbox", "Buy milk", false);
    string result = new Services.Export.MarkdownFormatter ().format (rows);
    assert (result.contains ("### Inbox"));
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/export/csv/quote-plain",    test_csv_quote_plain);
    Test.add_func ("/export/csv/quote-escape",   test_csv_quote_escapes_inner_quote);
    Test.add_func ("/export/csv/priority-p1",    test_csv_priority_label_p1);
    Test.add_func ("/export/csv/priority-none",  test_csv_priority_label_none);
    Test.add_func ("/export/csv/row",            test_csv_row);
    Test.add_func ("/export/csv/header",         test_csv_has_header);
    Test.add_func ("/export/md/unchecked",        test_markdown_unchecked);
    Test.add_func ("/export/md/checked",          test_markdown_checked);
    Test.add_func ("/export/md/section-heading",  test_markdown_section_heading);
    Test.add_func ("/export/taskpaper/task", test_taskpaper_task_line);
    Test.add_func ("/export/taskpaper/done", test_taskpaper_done_tag);
    Test.add_func ("/export/opml/envelope",          test_opml_envelope);
    Test.add_func ("/export/opml/task-outline",      test_opml_task_outline);
    Test.add_func ("/export/opml/escape-ampersand",  test_opml_escapes_ampersand);
    Test.add_func ("/export/omni-csv/header",      test_omni_csv_header);
    Test.add_func ("/export/omni-csv/flagged-p1",  test_omni_csv_flagged_p1);
    Test.add_func ("/export/omni-csv/not-flagged", test_omni_csv_not_flagged_p4);
    Test.add_func ("/export/ods/content-xml", test_ods_content_xml_has_header);
    return Test.run ();
}
