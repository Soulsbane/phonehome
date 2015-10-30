import std.stdio : writeln;
import std.string : lineSplitter, strip, toLower, indexOf, startsWith, removechars, CaseSensitive;
import std.file : exists, readText, mkdirRecurse;
import std.array : empty, split;
import std.conv : to;
import std.path : buildNormalizedPath;

import mustache;
alias Mustache = MustacheEngine!(string);

import raijin;

enum PHONE_BOOK_ENTRY_SIZE = [__traits(allMembers, PhoneBookEntry)].length;
enum DEFAULT_PHONE_BOOK_NAME = "phonebook.csv";

ConfigPath _AppConfigPath;

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
	this()
	{
		immutable string configFilePath = buildNormalizedPath(_AppConfigPath.getConfigDir("config"), "app.config");
		immutable bool loaded = config.loadFile(configFilePath);

		if(!loaded)
		{
			writeln("FAILED to load configuration file!");
		}
	}

	override void onValidArgs() @trusted
	{
		string searchTerm = safeGet(1);

		debug
		{
			processPhoneBookEntries("test.csv", searchTerm, get!bool("multiple"));
		}
		else
		{
			processPhoneBookEntries(config["phonebook"], searchTerm, get!bool("multiple"));
		}

	}

	override void onValidArg(immutable string argument) @trusted
	{
		if(argument == "phonebook")
		{
			string phoneBookName;
			immutable bool isFlag = isFlag("phonebook");

			if(isFlag) // INFO: The user passed -phonebook instead of -phonebook=name.csv causing CommandLineArgs to set phoneBookName to true
			{
				phoneBookName = DEFAULT_PHONE_BOOK_NAME;
			}
			else
			{
				phoneBookName = get("phonebook");
			}

			config["phonebook"] = phoneBookName;
		}
		if(argument == "template")
		{
			config["template"] = get("template");
		}

		config.save();
	}
private:
	KeyValueConfig config;
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

private string generateMustacheMembers()
{
	auto phoneBookEntryMembers = [__traits(allMembers, PhoneBookEntry)];
	string genStr;

	foreach(member; phoneBookEntryMembers)
	{
		genStr ~= "context[\"" ~ member ~ "\"] = entry." ~ member ~ ";";
	}

	return genStr;
}

void processPhoneBookEntries(immutable string phoneBookName, immutable string searchTerm, bool allowMultipleEntries = false) @trusted
{
	auto lines = loadPhoneBook(phoneBookName).lineSplitter();
	uint entryCount = 0;
	PhoneBookEntry[] entries;
	KeyValueConfig config;
	immutable string configFilePath = buildNormalizedPath(_AppConfigPath.getConfigDir("config"), "app.config");
	immutable bool loaded = config.loadFile(configFilePath);

	if(!loaded)
	{
		writeln("FAILED to load configuration file!");
	}

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
			auto args = new CommandLineArgs;
			immutable bool listAllEntries = args.get!bool("list-all");

			if(values.length == PHONE_BOOK_ENTRY_SIZE) // Make sure the phone book entry matches the number of field in PhoneBookEntry struct
			{
				mixin(generatedStruct);
				auto cs = cast(CaseSensitive)(args.get!bool("case-sensitive"));

				if(listAllEntries)
				{
					entries ~= entry;
					++entryCount;
				}
				else
				{
					if(entry.name.find(searchTerm, cs) || entry.nickName.find(searchTerm, cs))
					{
						entries ~= entry;
						++entryCount;
					}
				}
			}

			if(!allowMultipleEntries && entryCount > 0)
			{
				if(!listAllEntries)
				{
					break;
				}
			}
		}
	}

	if(entryCount == 0)
	{
		if(searchTerm.startsWith("-"))
		{
			writeln("No entries found in phonebook: ", phoneBookName);
		}
		else
		{
			writeln("No entries found matching ", searchTerm, " in phonebook: ", phoneBookName);
		}
	}
	else
	{
		writeln("Found ", to!string(entryCount), " ", pluralize("entry", entryCount), ":\n");

		Mustache mustache;
		auto context = new Mustache.Context;
		immutable string defaultTemplateFile = buildNormalizedPath(_AppConfigPath.getConfigDir("templates"), config.get("template", "default"));

		createDefaultTemplate();

		foreach (entry; entries)
		{
			mixin(generateMustacheMembers());
			writeln(mustache.render(defaultTemplateFile, context));
		}
	}
}

string loadPhoneBook(immutable string phoneBookName) @trusted
{
	string text;
	immutable string phoneBookPath = buildNormalizedPath(_AppConfigPath.getConfigDir("phonebooks"), phoneBookName);
	immutable string phoneBookFilesDir = _AppConfigPath.getConfigDir("phonebooks");

	if(exists(phoneBookPath))
	{
		text = readText(phoneBookPath);
	}
	else
	{
		mkdirRecurse(phoneBookFilesDir);
		auto f = File(phoneBookPath, "w+"); // Create an empty phone book and insert dummy data.

		text = "Uncle Tom;Tommy;123-4567;987-6543;211-2345\n";
		text ~= "Utada Hikaru;Hikki;111-1111;111-1983;222-1983";
		f.write(text);
	}

	return text;
}

void setupAppConfig()
{
	immutable string configFilePath = buildNormalizedPath(_AppConfigPath.getConfigDir("config"), "app.config");

	_AppConfigPath.createConfigDir("config");
	_AppConfigPath.createConfigDir("phonebooks");
	_AppConfigPath.createConfigDir("templates");

	if(!exists(configFilePath))
	{
		auto f = File(configFilePath, "w+");
		f.writeln("phonebook=phonebook.csv");
	}
}

void createDefaultTemplate()
{
	immutable string defaultTemplateFile = buildNormalizedPath(_AppConfigPath.getConfigDir("templates"), "default.mustache");

	if(!exists(defaultTemplateFile))
	{
		immutable string defaultTemplateText = import("default.mustache");
		auto f = File(defaultTemplateFile, "w+");

		f.write(defaultTemplateText);
	}
}

void main(string[] arguments)
{
	_AppConfigPath = new ConfigPath("Raijinsoft", "PhoneHome");
	auto args = new PhoneHomeArgs;

	setupAppConfig();

	args.addCommand("multiple", "false", "Allow multiple matches. For example Bob could match Bob Jones or Bob Evans");
	args.addCommand("case-sensitive", "false", "Enable case sensitive matching");
	args.addCommand("list-all", "false", "Output every entry in the phone book.");
	args.addCommand("phonebook", "phonebook.csv", "Set the phonebook to use.");
	args.addCommand("template", "default", "Set the output template to use.");
	// TODO: Add command for setting output template.

	args.processArgs(arguments, IgnoreFirstArg.yes);
}
