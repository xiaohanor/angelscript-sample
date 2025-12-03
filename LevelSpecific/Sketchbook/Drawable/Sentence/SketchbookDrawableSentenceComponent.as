enum ESketchbookDrawableSentenceDirection
{
	LeftToRight,
	RightToLeft,
};

event void FSketchbookDrawableSentenceOnLanguageChanged();

UCLASS(NotBlueprintable)
class USketchbookDrawableSentenceComponent : USketchbookDrawableComponent
{
	access Internal = private, USketchbookDrawableSentenceVisualizer, USketchbookEditorUtilityWidget;

	default TickableWhenPaused = true;

	/**
	 * The words in English
	 * Includes advanced features like delays
	 */
	UPROPERTY(EditAnywhere, Category = "Drawable Sentence", Meta = (TitleProperty = "Word"))
	access:Internal TArray<FSketchbookWord> Words;

	/**
	 * The words in the current non-English language.
	 * Only contains bounds.
	 */
	UPROPERTY(VisibleInstanceOnly, Transient, Category = "Drawable Sentence", Meta = (TitleProperty = "Word"))
	private TArray<FSketchbookWord> LocalizedWords;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence|Draw")
	private float DrawSpeed = Sketchbook::Sentence::DefaultDrawSpeed;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence|Erase")
	private float EraseSpeed = Sketchbook::Sentence::DefaultEraseSpeed;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence|Erase")
	bool bEraseInClosestDirection = true;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence|Erase", Meta = (EditCondition = "!bEraseInClosestDirection"))
	ESketchbookDrawableSentenceDirection EraseDirection = ESketchbookDrawableSentenceDirection::RightToLeft;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence", AdvancedDisplay)
	UMaterialInterface SketchbookMaterial = nullptr;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence", AdvancedDisplay)
	float BoundsVerticalMultiplier = 0.6;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence", AdvancedDisplay)
	float OriginVerticalOffset = 5;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence", AdvancedDisplay)
	float DrawHeightOffset = -10;

	UPROPERTY(EditAnywhere, Category = "Drawable Sentence", AdvancedDisplay)
	bool bDisableLocFontChange = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	USketchbookFontLookupDataAsset FontLookup;

	private UTextRenderComponent CachedTextRenderComp;

	private FName CachedCurrentLanguage;
	private FString CachedCurrentLanguageText;

	FSketchbookDrawableSentenceOnLanguageChanged OnLanguageChanged;

#if EDITOR
	private FVector PreviousActorScale = FVector::ZeroVector;
	private float PreviousTextScale = -1;
	private FString PreviousText;

	void UpdateInEditor(bool bForce) override
	{
		Super::UpdateInEditor(bForce);

		if(SketchbookMaterial == nullptr)
		{
			SketchbookMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Script/Engine.Material'/Game/LevelSpecific/Sketchbook/Shaders/M_SketchBook_Word.M_SketchBook_Word'"));
			check(SketchbookMaterial != nullptr, "Failed to load M_SketchBook_MeshReveal. Has it been moved?");
		}
		
		auto TextRenderComp = GetTextRenderComponent();
		if(TextRenderComp == nullptr)
			return;

		Owner.SetActorLabel(f"Sentence \"{TextRenderComp.Text.ToString()}\"");

		bool bTransformChanged = false;

		if(PreviousTextScale > 0 && !Math::IsNearlyEqual(PreviousTextScale, TextRenderComp.WorldSize))
			bTransformChanged = true;
		else if(!PreviousActorScale.IsNearlyZero() && !PreviousActorScale.Equals(Owner.ActorScale3D))
			bTransformChanged = true;

		bool bTextChanged = false;
		if(TextRenderComp.Text.ToString() != PreviousText)
			bTextChanged = true;
			
		AutoFitWords(bTransformChanged || bTextChanged || bForce);

		PreviousTextScale = TextRenderComp.WorldSize;
		PreviousActorScale = Owner.ActorScale3D;
		PreviousText = TextRenderComp.Text.ToString();

		SetTextRevealRatio(PreviewFraction, bPreviewErase);
	}

	private void AutoFitWords(bool bForce)
	{
		auto TextComp = GetTextRenderComponent();
		if(TextComp == nullptr)
		{
			PrintWarning(f"No TextRenderComponent found by SketchbookPenDrawableWordComponent on {Owner}", 0);
			return;
		}

		FString TextString = TextComp.Text.ToString();

		TArray<FString> Delimiters;
		Delimiters.Add(" ");

		TArray<FString> WordStrings;
		TextString.ParseIntoArray(WordStrings, Delimiters, true);

		while(Words.Num() < WordStrings.Num())
			Words.Add(FSketchbookWord());

		while(Words.Num() > WordStrings.Num())
			Words.RemoveAtSwap(Words.Num() - 1);

		FString Sentence;
		bool bCenterText = TextComp.HorizontalAlignment == EHorizTextAligment::EHTA_Center;
		if(bCenterText)
		{
			// The bounds per word assumes left alignment, set it to left here, the we set it back to center later
			TextComp.HorizontalAlignment = EHorizTextAligment::EHTA_Left;
		}

		bool bWordHasChanged = false;

		for(int i = 0; i < WordStrings.Num(); i++)
		{
			auto WordString = WordStrings[i];

			if(Words[i].Word != WordString || bWordHasChanged || bForce)
			{
				bWordHasChanged = true;
				Words[i].Word = WordString;

				const FBoxSphereBounds WordBounds = TextComp.PreviewCalcBounds(WordString, FTransform::Identity);

				FVector Extents = WordBounds.BoxExtent;
				Words[i].Bounds = FVector2D(Extents.Y, Extents.Z * BoundsVerticalMultiplier);

				const FBoxSphereBounds SentenceBounds = TextComp.PreviewCalcBounds(Sentence, FTransform::Identity);

				FVector Origin = SentenceBounds.Origin;
				Origin *= 2;	// One sided extents to two sided
				float StartX = Origin.Y;
				Words[i].Origin = FVector2D(-StartX, Extents.Z + OriginVerticalOffset);

				Words[i].UpdateType(WordString);
			}

			Sentence += WordString + " ";
		}

		if(bCenterText)
		{
			if(bWordHasChanged || bForce)
			{
				const FBoxSphereBounds FullSentenceBounds = TextComp.PreviewCalcBounds(TextComp.Text.ToString(), FTransform::Identity);

				// Move all words over haft the extent of the full sentence bounds
				for(FSketchbookWord& Word : Words)
				{
					Word.Origin -= FVector2D(FullSentenceBounds.BoxExtent.Y, 0);
				}
			}

			// Reset the horizontal alignment back
			TextComp.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
		}
	}

	UFUNCTION(CallInEditor, Category = "Drawable Word")
	private void ForceAutoFitWords()
	{
		AutoFitWords(true);
	}
#endif

	const TArray<FSketchbookWord>& GetWords() const
	{
		if(SketchbookLocHelpers::IsEnglish() || LocalizedWords.IsEmpty())
			return Words;
		else
			return LocalizedWords;
	}

	int GetWordCount() const
	{
		if(SketchbookLocHelpers::IsEnglish())
			return Words.Num();
		else
			return LocalizedWords.Num();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		CachedTextRenderComp = UTextRenderComponent::Get(Owner);

#if EDITOR
		CachedCurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();
#else
		CachedCurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif

		CachedCurrentLanguageText = CachedTextRenderComp.Text.ToString();

		bool bUpdateWords = false;
#if EDITOR
		if (!CachedCurrentLanguage.IsNone())
		{
			bUpdateWords = true;
		}
#else
		if (!Online::IsEnglish())
		{
			bUpdateWords = true;
		}
#endif
		if (IsValid(FontLookup) && !bDisableLocFontChange)
		{
			const bool bChangedFont = SketchbookLocHelpers::ApplyRenderTextFont(FontLookup, CachedTextRenderComp);
			if (bChangedFont)
			{
				bUpdateWords = true;
			}
		}

		if (bUpdateWords)
		{
			SketchbookLocHelpers::UpdateLocalizedWordsRuntime(this, LocalizedWords);
			OnLanguageChanged.Broadcast();
		}
	}

	// OA: Beware, this ticks while paused so we can update the font while the options menu is open
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		UpdateLocalization();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Super::OnActorEnabled();
		
		// We don't tick while disabled, so we force an update here before we are used
		UpdateLocalization();
	}

	void UpdateLocalization()
	{
#if EDITOR
	const FName CurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();
#else
	const FName CurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif

		if (CurrentLanguage != CachedCurrentLanguage)
		{
			const FString CurrentText = CachedTextRenderComp.Text.ToString();
			if(CachedCurrentLanguageText == CurrentText)
			{
				// The text update is delayed
				// Wait for it to actually change before switching the font and updating the words
				return;
			}

			CachedCurrentLanguage = CurrentLanguage;
			CachedCurrentLanguageText = CurrentText;

			if (IsValid(FontLookup) && !bDisableLocFontChange)
			{
				SketchbookLocHelpers::ApplyRenderTextFont(FontLookup, CachedTextRenderComp);
			}

			SketchbookLocHelpers::UpdateLocalizedWordsRuntime(this, LocalizedWords);
			OnLanguageChanged.Broadcast();
		}
	}

	float GetDrawSpeed() const
	{
		return DrawSpeed;
	}

	float GetDrawVerticalFrequency() const
	{
		return ModifyBasedOnDrawSpeed(Sketchbook::Sentence::DrawVerticalFrequency);
	}

	float GetDrawHorizontalFrequency() const
	{
		return ModifyBasedOnDrawSpeed(Sketchbook::Sentence::DrawHorizontalFrequency);
	}

	float GetDrawPitchFrequency() const
	{
		return ModifyBasedOnDrawSpeed(Sketchbook::Sentence::DrawPitchFrequency);
	}

	float GetDrawYawFrequency() const
	{
		return ModifyBasedOnDrawSpeed(Sketchbook::Sentence::DrawYawFrequency);
	}

	float GetEraseSpeed() const
	{
		return EraseSpeed;
	}

	float GetEraseVerticalFrequency() const
	{
		return ModifyBasedOnEraseSpeed(Sketchbook::Sentence::EraseVerticalFrequency);
	}

	float GetTravelToNextWordDuration() const
	{
		if(IsDrawnOrBeingDrawn())
			return Sketchbook::Sentence::TravelToNextWordsDuration / GetSpeedMultiplier(true);
		else
			return Sketchbook::Sentence::TravelToNextWordsDuration / GetSpeedMultiplier(false);
	}

	float GetSpeedMultiplier(bool bErase) const
	{
		if(bErase)
			return EraseSpeed / Sketchbook::Sentence::DefaultEraseSpeed;
		else
			return DrawSpeed / Sketchbook::Sentence::DefaultDrawSpeed;
	}

	float ModifyBasedOnDrawSpeed(float Value) const
	{
		return Value * GetSpeedMultiplier(false);
	}

	float ModifyBasedOnEraseSpeed(float Value) const
	{
		return Value * GetSpeedMultiplier(true);
	}

	bool IsAllCaps() const
	{
		for(auto Word : GetWords())
		{
			if(!Word.bAllCaps)
				return false;
		}

		return true;
	}

	private UMaterialInstanceDynamic GetTextMaterialInstance() const
	{
		auto TextRenderer = GetTextRenderComponent();

		auto TextDynamicMaterial = Cast<UMaterialInstanceDynamic>(TextRenderer.GetMaterial(0));

		if (TextDynamicMaterial == nullptr)
			TextDynamicMaterial = TextRenderer.CreateDynamicMaterialInstance(0, SketchbookMaterial);

		return TextDynamicMaterial;
	}

	void SetTextRevealRatio(float Ratio, bool bErase)
	{
		auto MaterialInstance = GetTextMaterialInstance();

		if(bErase)
		{
			int FlipDirection = 0;
			if(EraseDirection == ESketchbookDrawableSentenceDirection::LeftToRight)
				FlipDirection = 1;

			MaterialInstance.SetScalarParameterValue(n"Visible", 1.0 - Ratio);
			MaterialInstance.SetScalarParameterValue(n"FlipDirection", FlipDirection);
		}
		else
		{
			MaterialInstance.SetScalarParameterValue(n"Visible", Ratio);
			MaterialInstance.SetScalarParameterValue(n"FlipDirection", 0);
		}

		if(Ratio < 0)
			Print(f"SetTextRevealRatio {Ratio}");


	}

	void PrepareTravelTo(bool bErase, FVector TravelFromLocation) override
	{
		UpdateLocalization();

		Super::PrepareTravelTo(bErase, TravelFromLocation);

		if(bErase && bEraseInClosestDirection)
		{
			FVector LeftLocation;
			FVector RightLocation;

			if(LocalizedWords.IsEmpty())
			{
				// LocalizedWords have not yet been generated!
				LeftLocation = Words[0].GetWorldOrigin(this);
				RightLocation = Words.Last().GetDrawEndLocation(this);
			}
			else
			{
				LeftLocation = GetWords()[0].GetWorldOrigin(this);
				RightLocation = GetWords().Last().GetDrawEndLocation(this);
			}

			const float DistanceToLeft = TravelFromLocation.Distance(LeftLocation);
			const float DistanceToRight = TravelFromLocation.Distance(RightLocation);

			if(DistanceToLeft < DistanceToRight)
				EraseDirection = ESketchbookDrawableSentenceDirection::LeftToRight;
			else
				EraseDirection =  ESketchbookDrawableSentenceDirection::RightToLeft;
		}
	}

	FVector GetTravelToLocation(bool bErase) const override
	{
		if(GetWords().IsEmpty())
			return Super::GetTravelToLocation(bErase);

		ESketchbookDrawableSentenceDirection Direction = bErase ? EraseDirection : ESketchbookDrawableSentenceDirection::LeftToRight;
		return GetStartLocation(Direction);
	}

	FVector GetTravelFromLocation(bool bErase) const override
	{
		if(GetWords().IsEmpty())
			return Super::GetTravelFromLocation(bErase);

		ESketchbookDrawableSentenceDirection Direction = bErase ? EraseDirection : ESketchbookDrawableSentenceDirection::LeftToRight;
		return GetEndLocation(Direction);
	}

	FVector GetStartLocation(ESketchbookDrawableSentenceDirection Direction) const
	{
		switch(Direction)
		{
			case ESketchbookDrawableSentenceDirection::LeftToRight:
				return GetWords()[0].GetDrawStartLocation(this);

			case ESketchbookDrawableSentenceDirection::RightToLeft:
				return GetWords().Last().GetDrawEndLocation(this);
		}
	}

	FVector GetEndLocation(ESketchbookDrawableSentenceDirection Direction) const
	{
		switch(Direction)
		{
			case ESketchbookDrawableSentenceDirection::LeftToRight:
				return GetStartLocation(ESketchbookDrawableSentenceDirection::RightToLeft);

			case ESketchbookDrawableSentenceDirection::RightToLeft:
				return GetStartLocation(ESketchbookDrawableSentenceDirection::LeftToRight);
		}
	}

	void UpdateDrawnFraction(float Fraction, bool bErase, FPlane DrawPlane = FPlane()) override
	{
		Super::UpdateDrawnFraction(Fraction, bErase, DrawPlane);
		
		SetTextRevealRatio(Fraction, bErase);
	}

	UTextRenderComponent GetTextRenderComponent() const
	{
		if(CachedTextRenderComp != nullptr)
			return CachedTextRenderComp;

		return UTextRenderComponent::Get(Owner);
	}

	void LerpSentence(float DrawnAlpha, int&out OutWordIndex, float&out OutWordAlpha, bool&out bOutBetweenWords)
	{
		OutWordIndex = 0;
		OutWordAlpha = 0.0;
		bOutBetweenWords = false;

		const float TargetDistance = DrawnAlpha * GetSentenceWidth();

		for(int i = 0; i < GetWordCount(); i++)
		{
			const FSketchbookWord& Word = GetWords()[i];

			if(Word.Origin.X < TargetDistance)
			{
				// Too early
				continue;
			}

			if(TargetDistance < Word.Origin.X + Word.GetWordWidth())
			{
				// We landed in the middle of a word
				OutWordIndex = i;
				OutWordAlpha = Math::GetMappedRangeValueClamped(
					FVector2D(Word.Origin.X, Word.Origin.X + Word.GetWordWidth()),
					FVector2D(0, 1),
					TargetDistance
				);
				return;
			}
			else
			{
				if(i < GetWordCount() - 1)
				{
					// We landed between words
					// Pick the previous word as the index
					OutWordIndex = i;

					// Alpha is between previous and next word
					auto NextWord = Words[i + 1];
					OutWordAlpha = Math::GetMappedRangeValueClamped(
						FVector2D(Word.Origin.X + Word.GetWordWidth(), NextWord.Origin.X),
						FVector2D(0, 1),
						TargetDistance
					);
					
					bOutBetweenWords = true;
					return;
				}
				else
				{
					// We are past the last word
					break;
				}
			}
		}

		OutWordIndex = GetWordCount() - 1;
		OutWordAlpha = 1.0;
	}
	
	void GetSentenceXMinMax(float&out OutMin, float&out OutMax) const
	{
		if(GetWords().IsEmpty())
		{
			OutMin = 0;
			OutMax = 0;
			return;
		}

		OutMin = GetWords()[0].Origin.X;
		OutMax = GetWords().Last().Origin.X + (GetWords().Last().GetWordWidth());
	}

	void GetSentenceYMinMax(float&out OutMin, float&out OutMax) const
	{
		if(GetWords().IsEmpty())
		{
			OutMin = 0;
			OutMax = 0;
			return;
		}

		OutMin = BIG_NUMBER;
		OutMax = -BIG_NUMBER;

		for(auto Word : GetWords())
		{
			OutMin = Math::Min(OutMin, Word.Origin.Y);
			OutMax = Math::Max(OutMax, Word.Origin.Y + Word.Bounds.Y);
		}
	}

	float GetSentenceWidth() const
	{
		float Min;
		float Max;
		GetSentenceXMinMax(Min, Max);
		return Max - Min;
	}

	float GetSentenceHeight() const
	{
		float Min;
		float Max;
		GetSentenceYMinMax(Min, Max);
		return Max - Min;
	}

	float GetWordSentenceAlpha(int WordIndex, float WordFraction) const
	{
		auto Word = GetWords()[WordIndex];
		float WordX = Math::Lerp(Word.Origin.X, Word.Origin.X + Word.GetWordWidth(), WordFraction);

		float Min;
		float Max;
		GetSentenceXMinMax(Min, Max);
		return Math::NormalizeToRange(WordX, Min, Max);
	}

	float GetSentenceDrawDuration(bool bLocalized) const
	{
		float SentenceDuration = 0;

		if(bLocalized)
		{
			for(auto Word : GetWords())
				SentenceDuration += Word.GetDrawDuration(this, true);

			// Take traveling between words into account
			SentenceDuration += (GetWords().Num() - 1) * GetTravelToNextWordDuration();
		}
		else
		{
			for(auto Word : Words)
				SentenceDuration += Word.GetDrawDuration(this, true);

			// Take traveling between words into account
			SentenceDuration += (Words.Num() - 1) * GetTravelToNextWordDuration();
		}

		return SentenceDuration;
	}

	float GetSentenceEraseDuration() const
	{
		float SentenceDuration = 0;

			// Always use english words for erase duration
		for(auto Word : Words)
			SentenceDuration += Word.GetEraseDuration(this);

		return SentenceDuration;
	}

#if EDITOR
	FString GetEditorString() const override
	{
		return GetTextRenderComponent().Text.ToString();
	}

	void CalculateEditorBounds(FVector&out OutOrigin, FVector&out OutExtents) const override
	{
		auto Bounds = GetTextRenderComponent().GetBounds();
		OutOrigin = Bounds.Origin;
		OutExtents = Bounds.BoxExtent;
	}
#endif

#if !RELEASE
	void DebugDrawBounds()
	{
		for(auto Word : GetWords())
		{
			FVector Location;
			FVector Extents;
			Word.GetWorldBounds(this, Location, Extents);

			Debug::DrawDebugBox(Location, Extents, CachedTextRenderComp.WorldRotation, FLinearColor::Yellow, 3);
		}

		Debug::DrawDebugPoint(GetStartLocation(ESketchbookDrawableSentenceDirection::LeftToRight), 1, FLinearColor::Green);
		Debug::DrawDebugPoint(GetEndLocation(ESketchbookDrawableSentenceDirection::LeftToRight), 1, FLinearColor::Red);
	}
#endif
};

#if EDITOR
class USketchbookDrawableSentenceVisualizer : USketchbookDrawableVisualizer
{
	default VisualizedClass = USketchbookDrawableSentenceComponent;

	UPROPERTY()
	FName SelectedWord = NAME_None;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto DrawableSentenceComp = Cast<USketchbookDrawableSentenceComponent>(Component);
		if(DrawableSentenceComp == nullptr)
			return;

		Editor::ActivateVisualizer(DrawableSentenceComp);

		auto TextComp = DrawableSentenceComp.GetTextRenderComponent();
		if(TextComp == nullptr)
			return;

		float SentenceDuration = 0;

		for(int i = 0; i < DrawableSentenceComp.Words.Num(); i++)
		{
			auto Word = DrawableSentenceComp.Words[i];

			const bool bHasSelectedAnything = SelectedWord != NAME_None;
			bool bIsSelected = Word.Word == SelectedWord.ToString();

			if(!bHasSelectedAnything)
				bIsSelected = true;

			FVector Location;
			FVector Extents;
			Word.GetWorldBounds(DrawableSentenceComp, Location, Extents);

			FLinearColor Color = bIsSelected ? FLinearColor::Yellow : FLinearColor::White;

			SetHitProxy(FName(Word.Word), EVisualizerCursor::Hand);

			DrawWireBox(Location, Extents, TextComp.ComponentQuat, Color, 3);
			DrawLine(Word.GetDrawStartLocation(DrawableSentenceComp), Word.GetDrawEndLocation(DrawableSentenceComp), FLinearColor::Black, 1);

			ClearHitProxy();

			float WordDurationNoDelays = Word.GetDrawDuration(DrawableSentenceComp, false);
			SentenceDuration += Word.GetDrawDuration(DrawableSentenceComp, true);

			if(bIsSelected)
			{
				FString DebugInfo = f"Word {i}: {Word.Word}"
					+ f"\nDuration: {WordDurationNoDelays:.2} seconds"
				;

				if(!Math::IsNearlyEqual(Word.DrawRate, 1.0))
					DebugInfo += f"\nDrawRate: {Word.DrawRate:.1}";

				if(Word.PreDelay > 0)
					DebugInfo += f"\nPre Delay: {Word.PreDelay}";

				if(Word.PostDelay > 0)
					DebugInfo += f"\nPost Delay: {Word.PostDelay}";

				if(Word.WordType != ESketchbookWordType::Word)
					DebugInfo += f"\nType: {Word.WordType:n}";

				DrawWorldString(DebugInfo, Word.GetWorldOrigin(DrawableSentenceComp), Color);
			}

		}

		DrawWorldString(f"Sentence Width: {DrawableSentenceComp.GetSentenceWidth():.2},\nSentence Duration {SentenceDuration:.2}", TextComp.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
	                         EInputEvent Event)
	{
		Editor::BeginTransaction("Select Word", this);
		Modify();
		SelectedWord = HitProxy;
		Editor::EndTransaction();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		SelectedWord = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		if(!HasSelectedWord())
			return false;

		FSketchbookWord Word = GetSelectedWordConst();

		OutLocation = Word.GetWorldOrigin(GetSelectedDrawableSentenceComp());
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(!HasSelectedWord())
			return false;

		Editor::BeginTransaction("Transform Word", EditingComponent);
		EditingComponent.Modify();

		FSketchbookWord& Word = GetSelectedWordRef();
		FTransform WorldTransform = GetTextRenderComponentTransform();

		FVector LocalTranslate = WorldTransform.InverseTransformVectorNoScale(DeltaTranslate);
		Word.Origin += FVector2D(-LocalTranslate.Y, LocalTranslate.Z);

		FVector LocalScale = DeltaScale;
		Word.Bounds += FVector2D(LocalScale.Y, LocalScale.Z);
		Word.Bounds = FVector2D(Math::Max(Word.Bounds.X, 0), Math::Max(Word.Bounds.Y, 0));

		Editor::EndTransaction();

		return true;
	}

	FTransform GetTextRenderComponentTransform() const
	{
		auto TextComp = UTextRenderComponent::Get(EditingComponent.Owner);
		return TextComp.WorldTransform;
	}

	int GetSelectedWordIndex() const
	{
		if(SelectedWord == NAME_None)
			return -1;

		if(EditingComponent == nullptr)
			return -1;

		auto Drawable = Cast<USketchbookDrawableSentenceComponent>(EditingComponent);
		if(Drawable == nullptr)
			return -1;

		for(int i = 0; i < Drawable.Words.Num(); i++)
		{
			if(Drawable.Words[i].Word == SelectedWord.ToString())
				return i;
		}

		return -1;
	}

	bool HasSelectedWord() const
	{
		auto Drawable = Cast<USketchbookDrawableSentenceComponent>(EditingComponent);
		if(Drawable == nullptr)
			return false;

		if(SelectedWord == NAME_None)
			return false;

		if(EditingComponent == nullptr)
			return false;

		for(int i = 0; i < Drawable.Words.Num(); i++)
		{
			if(Drawable.Words[i].Word == SelectedWord.ToString())
				return true;
		}

		return false;
	}

	USketchbookDrawableSentenceComponent GetSelectedDrawableSentenceComp() const
	{
		return Cast<USketchbookDrawableSentenceComponent>(EditingComponent);
	}

	FSketchbookWord GetSelectedWordConst() const
	{
		auto Drawable = Cast<USketchbookDrawableSentenceComponent>(EditingComponent);

		for(int i = 0; i < Drawable.Words.Num(); i++)
		{
			if(Drawable.Words[i].Word == SelectedWord.ToString())
				return Drawable.Words[i];
		}

		return Drawable.Words[0];
	}

	FSketchbookWord& GetSelectedWordRef()
	{
		auto Drawable = Cast<USketchbookDrawableSentenceComponent>(EditingComponent);

		for(int i = 0; i < Drawable.Words.Num(); i++)
		{
			if(Drawable.Words[i].Word == SelectedWord.ToString())
				return Drawable.Words[i];
		}

		return Drawable.Words[0];
	}
};
#endif