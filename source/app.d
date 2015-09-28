import std.stdio;
import std.string : lineSplitter, strip, toLower, indexOf, startsWith, removechars, CaseSensitive;
import std.file : exists, readText;
import std.array : empty, split;
import std.conv : to;
import std.path : buildNormalizedPath;
import std.file : mkdirRecurse;

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

/*
*	Generates an PhoneBookEntry based on how many fields the struct PhoneBookEntry contains.
*/
private string generateEntry()
{
	string entryString = "immutable PhoneBookEntry entry = {";
	int i;

	while(i < PHONE_BOOK_ENTRY_SIZE)
	{
		if(i == PHONE_BOOK_ENTRY_SIZE - 1)
		{
			entryString ~= ("values[" ~ i.to!string ~ "]");
		}
		else
		{
			entryString ~= ("values[" ~ i.to!string ~ "], ");
		}
		++i;
	}

	entryString ~= "};";
	return entryString;
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

				if(values.length == PHONE_BOOK_ENTRY_SIZE) // Make sure the phone book entry matches the number of field in PhoneBookEntry struct
				{
					mixin(generateEntry());
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

string loadPhoneBook(immutable string phoneBookName) @trusted
{
	string text;
	immutable string phoneBookPath = buildNormalizedPath(getPhoneBookFilesDir(), phoneBookName);
	immutable string configFilesDir = getConfigFilesDir();
	immutable string phoneBookFilesDir = getPhoneBookFilesDir();

	if(exists(phoneBookPath))
	{
		text = readText(phoneBookPath);
	}
	else
	{
		mkdirRecurse(phoneBookFilesDir);
		auto f = File(phoneBookPath, "w+"); // Create an empty phone book and insert dummy data.

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
