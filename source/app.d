import std.stdio;
import std.csv;
import std.string : lineSplitter, strip, toLower, indexOf, startsWith, CaseSensitive;
import std.file : exists, readText;
import std.array : empty, split;

struct PhoneBookEntry
{
	string name;
	string nickName;
	string homeNumber;
	string cellNumber;
	string workNumber;
}

string pluralizeEntryCount(immutable uint count) pure @safe
{
	string pluralizedNumber;

	if(count == 1)
	{
		pluralizedNumber = "1 entry";
	}
	else
	{
		import std.conv : to;
		pluralizedNumber = to!string(count) ~ " entries";
	}

	return pluralizedNumber;
}

void processPhoneBookEntries(string phoneBookName, string searchTerm, bool allowMultipleEntries = false) @safe
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
				PhoneBookEntry entry = getPhoneBookEntry(values);

				entries ~= entry;
				++entryCount;

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
		writeln("Found ", pluralizeEntryCount(entryCount), ":\n");

		foreach(entry; entries)
		{
			writeln("     -==Entry==-");
			writeln("NAME: ", entry.name);
			writeln("HOME: ", entry.homeNumber);
			writeln("CELLPHONE: ", entry.cellNumber);
			writeln("WORK: ", entry.workNumber);
			writeln();
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

PhoneBookEntry getPhoneBookEntry(immutable string[] values) pure @safe
{
	PhoneBookEntry entry;
	int i;

	while(i < values.length)
	{
		final switch(i)
		{
			case 0:
				entry.name = values[0];
				break;
			case 1:
				entry.nickName = values[1];
				break;
			case 2:
				entry.homeNumber = values[2];
				break;
			case 3:
				entry.cellNumber = values[3];
				break;
			case 4:
				entry.workNumber = values[4];
				break;
		}
		++i;
	}
	return entry;
}

void main(string[] arguments)
{
	if(arguments.length > 1)
	{
		debug
		{
			processPhoneBookEntries("test.csv", arguments[1]);
		}
		else
		{
			processPhoneBookEntries("phonebook.csv", arguments[1]);
		}
	}
	else
	{
		writeln("No arguments supplied!");
	}
}
