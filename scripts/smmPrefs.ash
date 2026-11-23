script "smmPrefs";
since r27000;

/*
  Keep chosen KoLmafia preferences the same on every machine.

  The shared values live in data/smm-prefs.txt (one "name<TAB>value" per line).
  That file is in the KoL repository, so "git update" brings changes to every
  installation.

  Commands (gCLI):
    smmPrefs check     list every preference that differs from the file; changes nothing
    smmPrefs apply     set every preference that differs to the file's value
    smmPrefs capture   write this machine's current values back into the file
                       (on the development Mac the file is a link into the
                       repository, so commit and push afterwards)

  The file holds settings only: never passwords, logins, paths, daily
  counters or script state. See docs/shared-settings.md.
*/

string SMM_PREFS_FILE = "smm-prefs.txt";

// ASH compares strings with == without regard to case; preferences need an exact match.
boolean smmSame(string a, string b) {
    return length(a) == length(b) && index_of(a, b) == 0;
}

string smmTrim(string s) {
    return replace_all(create_matcher("^\\s+|\\s+$", s), "");
}

record smmPrefLine {
    boolean isPref;   // false for comments and blank lines
    string name;
    string value;
    string raw;
};

smmPrefLine[int] smmReadPrefsFile() {
    smmPrefLine[int] lines;
    buffer text = file_to_buffer(SMM_PREFS_FILE);
    if (length(text) == 0) {
        print("smmPrefs: " + SMM_PREFS_FILE + " is missing or empty. Run \"git update\".", "red");
        return lines;
    }
    foreach i, rawLine in split_string(text.to_string(), "\n") {
        string raw = replace_string(rawLine, "\r", "").to_string();
        smmPrefLine line = new smmPrefLine();
        line.isPref = false;
        line.raw = raw;
        string trimmed = smmTrim(raw);
        int tab = index_of(raw, "\t");
        if (trimmed != "" && !trimmed.starts_with("#") && tab > 0) {
            line.isPref = true;
            line.name = smmTrim(substring(raw, 0, tab));
            line.value = substring(raw, tab + 1);
        } else if (trimmed != "" && !trimmed.starts_with("#")) {
            print("smmPrefs: ignoring line without a tab: " + raw, "orange");
        }
        lines[count(lines)] = line;
    }
    return lines;
}

// Returns the number of preferences that differ (and were set, when apply is true).
int smmComparePrefs(boolean apply) {
    smmPrefLine[int] lines = smmReadPrefsFile();
    int differ = 0;
    int total = 0;
    foreach i, line in lines {
        if (!line.isPref) continue;
        total += 1;
        string current = get_property(line.name);
        if (smmSame(current, line.value)) continue;
        differ += 1;
        print(line.name + ": \"" + current + "\" -> \"" + line.value + "\"", apply ? "blue" : "gray");
        if (apply) set_property(line.name, line.value);
    }
    if (differ == 0) print("smmPrefs: all " + total + " shared preferences already match.", "green");
    else if (apply) print("smmPrefs: set " + differ + " of " + total + " shared preferences.", "green");
    else print("smmPrefs: " + differ + " of " + total + " shared preferences differ. Run \"smmPrefs apply\" to set them.", "blue");
    return differ;
}

void smmCapturePrefs() {
    smmPrefLine[int] lines = smmReadPrefsFile();
    if (count(lines) == 0) return;
    buffer out;
    int changed = 0;
    foreach i, line in lines {
        if (line.isPref) {
            string current = get_property(line.name);
            if (current.contains_text("\t") || current.contains_text("\n")) {
                print("smmPrefs: kept the file's value for " + line.name + " (current value has a tab or newline).", "orange");
                current = line.value;
            }
            if (!smmSame(current, line.value)) {
                print(line.name + ": \"" + line.value + "\" -> \"" + current + "\"", "blue");
                changed += 1;
            }
            out.append(line.name + "\t" + current);
        } else {
            out.append(line.raw);
        }
        if (i < count(lines) - 1) out.append("\n");
    }
    if (changed == 0) {
        print("smmPrefs: the file already matches this machine.", "green");
        return;
    }
    if (buffer_to_file(out, SMM_PREFS_FILE)) {
        print("smmPrefs: wrote " + changed + " changed values to data/" + SMM_PREFS_FILE + ". Commit and push it from the repository.", "green");
    } else {
        print("smmPrefs: could not write data/" + SMM_PREFS_FILE + ".", "red");
    }
}

void main(string command) {
    command = smmTrim(command).to_lower_case();
    if (command == "" || command == "check") smmComparePrefs(false);
    else if (command == "apply") smmComparePrefs(true);
    else if (command == "capture") smmCapturePrefs();
    else print("Usage: smmPrefs [check | apply | capture]", "red");
}
