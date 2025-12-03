// Display for a single license that should be displayed
struct FLicenseContent
{
	UPROPERTY()
	FString Title;
	UPROPERTY(Meta = (MultiLine = true))
	FString Text;
};

// An asset that keeps culture variants of licenses
class ULicenseAsset : UDataAsset
{
#if EDITOR
	UPROPERTY()
	TMap<FString, FString> SourceURLs;
#endif
	
	UPROPERTY()
	TMap<FString, FLicenseContent> LicensesByCulture;

#if EDITOR
	UFUNCTION(CallInEditor)
	void DownloadLicenses()
	{
		FAngelscriptExcludeScopeFromLoopTimeout ExcludeTimeout;
		Modify();

		for (auto Element : SourceURLs)
		{
			FString LicenseText = Editor::DownloadFileHttp(Element.Value);
			LicenseText = LicenseText.Replace("<br> ", "\n");
			LicenseText = LicenseText.Replace("<br>", "\n");
			LicenseText = LicenseText.Replace("<div style=\"background-color: white;\">", "");
			LicenseText = LicenseText.Replace("</div>", "");

			FLicenseContent& Content = LicensesByCulture.FindOrAdd(Element.Key);
			Content.Text = LicenseText;
		}
	}
#endif

	FLicenseContent GetLicenseForCulture(FString Culture)
	{
		Log("Retrieving license for culture "+Culture);
		FLicenseContent OutLicense;

		// Check for a license for this culture
		if (LicensesByCulture.Find(Culture, OutLicense))
			return OutLicense;

		// Check for a license with only the language from the culture
		if (Culture.Len() > 2 && LicensesByCulture.Find(Culture.Left(2), OutLicense))
			return OutLicense;

		// Check for chinese alternatives
		if (Culture == "zh-Hans" || Culture == "zh-Hans-CN" || Culture == "zh")
		{
			if (LicensesByCulture.Find("zh-CN", OutLicense))
				return OutLicense;
		}
		else if (Culture == "zh-Hant" || Culture == "zh-Hant-CN")
		{
			if (LicensesByCulture.Find("zh-TW", OutLicense))
				return OutLicense;
		}

		// Fall back to english license
		if (LicensesByCulture.Find("en", OutLicense))
			return OutLicense;

		// A dummy license
		OutLicense.Title = "Dummy License";
		OutLicense.Text = "No text was found for culture "+Culture;
		return OutLicense;
	}
};