UCLASS(NotBlueprintable, HideCategories = "Rendering Debug Activation Cooking Tags LOD Navigation")
class USketchbookLanguageOffsetComponent : USceneComponent
{
	default PrimaryComponentTick.bTickEvenWhenPaused = true;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Localization")
	ESketchbookLanguage EditorPreviewLanguage = ESketchbookLanguage::English;
#endif

	UPROPERTY(EditAnywhere, Category = "Localization")
	TMap<ESketchbookLanguage, FTransform> LanguageToWidgetTransform;
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::English, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::French, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::Spanish, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::Italian, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::German, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::Polish, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::Portuguese, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::Japanese, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::Korean, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::ChineseSimplified, FTransform::Identity);
	default LanguageToWidgetTransform.Add(ESketchbookLanguage::ChineseTraditional, FTransform::Identity);

	private FName CachedCurrentLanguage;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		UpdateLanguageTransform(EditorPreviewLanguage);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(AttachParent == nullptr)
		{
			PrintError(f"{this} is a root component! USketchbookLanguageOffsetComponent cannot be roots!");
			return;
		}

#if EDITOR
		FName CurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();

		if(CurrentLanguage == NAME_None)
			CurrentLanguage = SketchbookLocHelpers::GetLanguageName(ESketchbookLanguage::English);
#else
		FName CurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif

		if(CachedCurrentLanguage != CurrentLanguage)
		{
			UpdateLanguageTransform(SketchbookLocHelpers::GetLanguageEnum(CurrentLanguage));
			CachedCurrentLanguage = CurrentLanguage;
		}
	}

	void UpdateLanguageTransform(ESketchbookLanguage LanguageEnum)
	{
		FTransform WidgetTransform;
		if(LanguageToWidgetTransform.Find(LanguageEnum, WidgetTransform))
			SetRelativeTransform(WidgetTransform);
	}
}