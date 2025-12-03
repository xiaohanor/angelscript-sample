
FString GetTemporalLogBaseName(FString Path)
{
	int FoundIndex = 0;
	if (Path.FindLastChar('/', FoundIndex))
		return Path.RightChop(FoundIndex+1);
	return Path;
}

FString GetTemporalLogDisplayName(FString Path)
{
	FString DisplayName = Path;
	if (DisplayName.EndsWith("_0"))
		DisplayName = DisplayName.Left(DisplayName.Len() - 2);
	return DisplayName;
}

FString GetTemporalLogParentPath(FString Path)
{
	FString UpPath;
	int FoundIndex = 0;
	if (Path.FindLastChar('/', FoundIndex))
		UpPath = Path.Mid(0, FoundIndex);
	if (UpPath.Len() == 0)
		UpPath = "/";
	return UpPath;
}