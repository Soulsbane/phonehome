import std.stdio;
import std.string : lineSplitter, strip, toLower, indexOf, startsWith, removechars, CaseSensitive;
import std.file : exists, readText;
import std.array : empty, split;
import std.conv : to;

import mustache;
alias Mustache = MustacheEngine!(string);

import raijin;
import configpath;

enum PHONE_BOOK_ENTRY_SIZE = [__traits(allMembers, PhoneBookEntry)].length;

struct PhoneBookEntry
{
	string name;
	string nickName;
	string homeNumber;
	string cellNumber;
	string workNumber;
}

class PhoneHomeArgs : CommandLineArgs
{
	override void onValidArgs()
	{
		string searchTerm = safeGet(1);

		debug
		{
			processPhoneBookEntries("test.csv", searchTerm, get!bool("multiple"));
		}
		else
		{
			processPhoneBookEntries("phonebook.csv", searchTerm, get!bool("multiple"));
		}
	}
}

void processPhoneBookEntries(immutable string phoneBookName, immutable string searchTerm, bool allowMultipleEntries = false) @trusted
{
	auto lines = loadPhoneBook(phoneBookName).lineSplitter();
	uint entryCount = 0;
	PhoneBookEntry[] entries;

	foreach(line; lines)
	{
		line = strip(line);

		if(line.empty || line.startsWith("#"))
		{
			continue;
		}
		else
		{
			if(line.indexOf(searchTerm, CaseSensitive.no) != -1)
			{
				immutable string[] values = line.split(";");

				if(values.length == PHONE_BOOK_ENTRY_SIZE)
				{
					immutable PhoneBookEntry entry = { values[0], values[1], values[2], values[3], values[4] }; // FIXME: Maybe more size checking here before using values

					entries ~= entry;
					++entryCount;
				}

				if(!allowMultipleEntries)
				{
					break;
				}
			}
			else
			{
				continue;
			}
		}
	}

	if(entryCount == 0)
	{
		writeln("Can't phone home! No entries found matching ", searchTerm, " in the phonebook.");
	}
	else
	{
		writeln("Found ", pluralize("entry", entryCount), ":\n");

		Mustache mustache;
		auto context = new Mustache.Context;

		mustache.path  = "templates";

		foreach (entry; entries) {
		    context["name"] = entry.name;
		    context["homeNumber"] = entry.homeNumber;
		    context["cellNumber"] = entry.cellNumber;
		    context["workNumber"] = entry.workNumber;

			writeln(mustache.render("default", context));
		}

	}
}

string loadPhoneBook(immutable string phoneBookName) @safe
{
	string text;

	if(exists(phoneBookName))
	{
		text = readText(phoneBookName);
	}
	else
	{
		auto f = File(phoneBookName, "w+"); // Create an empty phone book and insert dummy data.

		text = "Uncle Tom;Tommy;123-4567;987-6543;211-2345";
		f.write(text);
	}

	return text;
}

void main(string[] arguments)
{
	auto args = new PhoneHomeArgs;

	args.addCommand("multiple", "false", "Allow multiple matches. For example Bob could match Bob Jones or Bob Evans");
	args.processArgs(arguments, IgnoreFirstArg.yes);
}
