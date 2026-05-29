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
    return Test.run ();
}
