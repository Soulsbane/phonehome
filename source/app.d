import std.stdio;
import std.csv;
import std.string : lineSplitter, strip, toLower, indexOf, CaseSensitive;
import std.file : exists, readText;
import std.array : empty;

struct PhoneBookEntry
{
	string name;
	string nickName;
	string homeNumber;
	string cellNumber;
}

void processPhoneBookEntries(string phoneBookName, string searchTerm, bool breakOnFound = false)
{
	auto lines = loadPhoneBook(phoneBookName).lineSplitter();
	uint entryCount = 0;

	foreach(line; lines)
	{
		line = strip(line);

		if(line.empty)
		{
			continue;
		}
		else
		{
			if(line.indexOf(searchTerm, CaseSensitive.no) != -1)
			{
				auto records = csvReader!PhoneBookEntry(line,';');

				foreach(record; records)
				{
					writeln("     -==Entry==-");
					writeln("NAME: ", record.name);
					writeln("HOME: ", record.homeNumber);
					writeln("CELLPHONE: : ", record.cellNumber);
					writeln();
				}

				++entryCount;

				if(breakOnFound)
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
		writeln("No entries found matching ", searchTerm, " in the phonebook.");
	}
}

string loadPhoneBook(immutable string phoneBookName)
{
	string text;

	if(exists(phoneBookName))
	{
		text = readText(phoneBookName);
	}
	else
	{
		auto f = File(phoneBookName, "w+"); // Create an empty phone book and insert dummy data.

		text = "Uncle Tom;Tommy;123-4567;987-6543";
		f.write(text);
	}

	return text;
}

void main(string[] arguments)
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
