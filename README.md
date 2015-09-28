#Description
PhoneHome is a bare bones application for storing and looking up phone numbers.

#How To Use
>phonehome searchterm

Will output the first match it finds.
>phonehome searchterm -multiple

Will output every match that it finds.

#Building
1. Clone https://github.com/Soulsbane/raijin
2. Add raijin to your dub repository dub add-local path_to_where_raijin_resides
3. Clone https://github.com/Soulsbane/phonehome
4. Run dub inside phonehome directory.

#Phone Book File Format
Phonehome uses a semicolon seperated values format in the following order:

>Name;Nickname;Home Phone;Cell Phone;Work Phone

Be sure to save your phone book to
>Linux: /home/username/.config/Raijinsoft/PhoneHome/phonebooks

>Windows: C:\Documents and Settings\username\Local Settings\Application Data\Raijinsoft\Phonehome\phonebooks

###Example Phone Book
>Uncle Tom;Tommy;123-4567;987-6543;211-2345
