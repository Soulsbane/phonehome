module configpath;

import std.path : buildNormalizedPath;
import std.file : exists, mkdirRecurse;

import standardpaths : writablePath, StandardPath;

enum string organizationName = "Raijinsoft";
enum string applicationName = "PhoneHome";

string getConfigDir() @safe
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName);
}

string getConfigFilesDir() @safe
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName, "config");
}

string getTemplateFilesDir() @safe
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName, "templates");
}

string getPhoneBookFilesDir() @safe
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName, "phonebooks");
}

void createConfigDir(string path)
{
	string normalPath = buildNormalizedPath(getConfigDir(), path);

	if(!exists(normalPath))
	{
		mkdirRecurse(normalPath);
	}
}
