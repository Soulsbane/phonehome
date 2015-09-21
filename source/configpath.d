module configpath;

import std.path;

import standardpaths;

enum string organizationName = "Raijinsoft";
enum string applicationName = "PhoneHome";

string getConfigDir()
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName);
}

string getConfigFilesDir()
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName, "config");
}

string getTemplateFilesDir()
{
	return buildNormalizedPath(writablePath(StandardPath.Config), organizationName, applicationName, "templates");
}
