
struct FSketchbookFontLanguage
{
	UPROPERTY()
	FName Culture;

	UPROPERTY()
	UFont Font;
}

class USketchbookFontLookupDataAsset : UDataAsset
{
	UPROPERTY()
	FSketchbookFontLanguage Default;

	UPROPERTY()
	TArray<FSketchbookFontLanguage> Specialized;
}

enum ESketchbookLanguage
{
	English,
	French,
	Spanish,
	Italian,
	German,
	Polish,
	Portuguese,
	Japanese,
	Korean,
	ChineseSimplified,
	ChineseTraditional,
};

namespace SketchbookLocHelpers
{
	FName GetLanguageName(ESketchbookLanguage Language)
	{
		switch(Language)
		{
			case ESketchbookLanguage::English:
				return n"en";
			case ESketchbookLanguage::French:
				return n"fr";
			case ESketchbookLanguage::Spanish:
				return n"es";
			case ESketchbookLanguage::Italian:
				return n"it";
			case ESketchbookLanguage::German:
				return n"de";
			case ESketchbookLanguage::Polish:
				return n"pl";
			case ESketchbookLanguage::Portuguese:
				return n"pt-BR";
			case ESketchbookLanguage::Japanese:
				return n"ja-JP";
			case ESketchbookLanguage::Korean:
				return n"ko-KR";
			case ESketchbookLanguage::ChineseSimplified:
				return n"zh-Hans";
			case ESketchbookLanguage::ChineseTraditional:
				return n"zh-Hant";
		}
	}

	ESketchbookLanguage GetLanguageEnum(FName LanguageName)
	{
		if(LanguageName == n"en")
			return ESketchbookLanguage::English;
		if(LanguageName == n"fr")
			return ESketchbookLanguage::French;
		if(LanguageName == n"es")
			return ESketchbookLanguage::Spanish;
		if(LanguageName == n"it")
			return ESketchbookLanguage::Italian;
		if(LanguageName == n"de")
			return ESketchbookLanguage::German;
		if(LanguageName == n"pl")
			return ESketchbookLanguage::Polish;
		if(LanguageName == n"pt-BR")
			return ESketchbookLanguage::Portuguese;
		if(LanguageName == n"ja-JP")
			return ESketchbookLanguage::Japanese;
		if(LanguageName == n"ko-KR")
			return ESketchbookLanguage::Korean;
		if(LanguageName == n"zh-Hans")
			return ESketchbookLanguage::ChineseSimplified;
		if(LanguageName == n"zh-Hant")
			return ESketchbookLanguage::ChineseTraditional;

		return ESketchbookLanguage::English;
	}

	UFont FindCurrentFont(USketchbookFontLookupDataAsset FontLookup)
	{
#if EDITOR
	const FName CurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();
#else
	const FName CurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif
		for (auto LangSpec : FontLookup.Specialized)
		{
			if (LangSpec.Culture == CurrentLanguage)
			{
				return LangSpec.Font;
			}
		}
		return FontLookup.Default.Font;
	}

	bool ApplyRenderTextFont(USketchbookFontLookupDataAsset FontLookup, UTextRenderComponent TextRender)
	{
		UFont CurrentFont = FindCurrentFont(FontLookup);
		if (TextRender.Font != CurrentFont)
		{
			TextRender.HazeSetFont(CurrentFont);

			// Update the font on the material
			UMaterialInterface Material = TextRender.GetMaterial(0);
			UMaterialInstanceDynamic MID = Cast<UMaterialInstanceDynamic>(Material);

			if(MID == nullptr)
				MID = TextRender.CreateDynamicMaterialInstance(0, Material);
			
			MID.SetFontParameterValue(n"Font", CurrentFont, 0);
			return true;
		}

		return false;
	}

	bool IsEnglish()
	{
#if EDITOR
		const FName CurrentLanguage = ::Editor::GetGameLocalizationPreviewLanguage();

		if(CurrentLanguage == NAME_None || CurrentLanguage == GetLanguageName(ESketchbookLanguage::English))
			return true;
		else
			return false;
#else
		return Online::IsEnglish();
#endif
	}

	void UpdateLocalizedWordsRuntime(
		const USketchbookDrawableSentenceComponent SentenceComp,
		TArray<FSketchbookWord>& LocalizedWords)
	{
		auto TextComp = UTextRenderComponent::Get(SentenceComp.Owner);
		if (!devEnsure(TextComp != nullptr, "No RenderTextComponent when updating sketchbook sentence words!"))
			return;

		FString TextString = TextComp.Text.ToString();

		TArray<FString> Delimiters;
		Delimiters.Add(" ");

		TArray<FString> WordStrings;
		TextString.ParseIntoArray(WordStrings, Delimiters, true);

		LocalizedWords.Reset(WordStrings.Num());
		LocalizedWords.SetNum(WordStrings.Num());

		FString Sentence;
		bool bCenterText = TextComp.HorizontalAlignment == EHorizTextAligment::EHTA_Center;
		if(bCenterText)
		{
			// The bounds per word assumes left alignment, set it to left here, the we set it back to center later
			TextComp.HorizontalAlignment = EHorizTextAligment::EHTA_Left;
		}

		for (int i = 0; i < WordStrings.Num(); i++)
		{
			auto WordString = WordStrings[i];

#if EDITOR
			LocalizedWords[i].Word = WordString;
#endif

			const FBoxSphereBounds WordBounds = TextComp.PreviewCalcBounds(WordString, FTransform::Identity);

			FVector Extents = WordBounds.BoxExtent;
			LocalizedWords[i].Bounds = FVector2D(Extents.Y, Extents.Z * SentenceComp.BoundsVerticalMultiplier);

			const FBoxSphereBounds SentenceBounds = TextComp.PreviewCalcBounds(Sentence, FTransform::Identity);

			FVector Origin = SentenceBounds.Origin;
			Origin *= 2; // One sided extents to two sided
			float StartX = Origin.Y;
			LocalizedWords[i].Origin = FVector2D(-StartX, Extents.Z + SentenceComp.OriginVerticalOffset);

			LocalizedWords[i].UpdateType(WordString);

			Sentence += WordString + " ";
		}

		if(bCenterText)
		{
			const FBoxSphereBounds FullSentenceBounds = TextComp.PreviewCalcBounds(TextComp.Text.ToString(), FTransform::Identity);

			// Move all words over haft the extent of the full sentence bounds
			for(FSketchbookWord& Word : LocalizedWords)
			{
				Word.Origin -= FVector2D(FullSentenceBounds.BoxExtent.Y, 0);
			}

			// Reset the horizontal alignment back
			TextComp.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
		}
	}
}
