import std.stdio;
import std.string : lineSplitter, strip, toLower, indexOf, startsWith, removechars, CaseSensitive;
import std.file : exists, readText, mkdirRecurse;
import std.array : empty, split;
import std.conv : to;
import std.path : buildNormalizedPath;

import mustache;
alias Mustache = MustacheEngine!(string);

import raijin;

enum PHONE_BOOK_ENTRY_SIZE = [__traits(allMembers, PhoneBookEntry)].length;
ConfigPath _AppConfig;

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
			immutable string[] values = line.split(";");
			immutable string generatedStruct = generateEntry();

			if(values.length == PHONE_BOOK_ENTRY_SIZE) // Make sure the phone book entry matches the number of field in PhoneBookEntry struct
			{
				mixin(generatedStruct);
				auto args = new CommandLineArgs;
				auto cs = boolToFlag!CaseSensitive(args.get!bool("casesensitive"));

				if(entry.name.find(searchTerm, cs) || entry.nickName.find(searchTerm, cs))
				{
					entries ~= entry;
					++entryCount;
				}
			}

			if(!allowMultipleEntries && entryCount > 0)
			{
				break;
			}
		}
	}

	if(entryCount == 0)
	{
		writeln("No entries found matching ", searchTerm, " in phonebook: ", phoneBookName);
	}
	else
	{
		writeln("Found ", to!string(entryCount), " ", pluralize("entry", entryCount), ":\n");

		Mustache mustache;
		auto context = new Mustache.Context;
		immutable string defaultTemplateFile = buildNormalizedPath(_AppConfig.getConfigDir("templates"), "default");

		createDefaultTemplate();

		foreach (entry; entries) {
		    context["name"] = entry.name;
		    context["homeNumber"] = entry.homeNumber;
		    context["cellNumber"] = entry.cellNumber;
		    context["workNumber"] = entry.workNumber;

			writeln(mustache.render(defaultTemplateFile, context));
		}

	}
}

string loadPhoneBook(immutable string phoneBookName) @trusted
{
	string text;
	immutable string phoneBookPath = buildNormalizedPath(_AppConfig.getConfigDir("phonebooks"), phoneBookName);
	immutable string phoneBookFilesDir = _AppConfig.getConfigDir("phonebooks");

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

void createConfigDirs()
{
	_AppConfig.createConfigDir("config");
	_AppConfig.createConfigDir("phonebooks");
	_AppConfig.createConfigDir("templates");
}

void createDefaultTemplate()
{
	immutable string defaultTemplateFile = buildNormalizedPath(_AppConfig.getConfigDir("templates"), "default.mustache");

	if(!exists(defaultTemplateFile))
	{
		immutable string defaultTemplateText = import("default.mustache");
		auto f = File(defaultTemplateFile, "w+");

		f.write(defaultTemplateText);
	}
}

void main(string[] arguments)
{
	auto args = new PhoneHomeArgs;
	_AppConfig = new ConfigPath("Raijinsoft", "PhoneHome");

	createConfigDirs();
	args.addCommand("multiple", "false", "Allow multiple matches. For example Bob could match Bob Jones or Bob Evans");
	args.addCommand("casesensitive", "false", "Enable case sensitive matching");

	args.processArgs(arguments, IgnoreFirstArg.yes);
}
