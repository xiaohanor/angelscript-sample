struct FAudioDebugMiscFlags
{
	UPROPERTY()
	EBankLoadState SelectedBankState;
	UPROPERTY()
	bool bShowRTPCs = false;
	UPROPERTY()
	bool bShowAuxSends = false;
	UPROPERTY()
	bool bShowOverlappingEnvironments = false;
	UPROPERTY()
	bool bShowAttenuationScaling = false;
	UPROPERTY()
	bool bShowInactiveAudioComponents = false;
	UPROPERTY()
	bool bShowZonesAttenuation = true;
	UPROPERTY()
	float ViewportScrollOffset = 0;
	UPROPERTY()
	EHazeLevelSequenceTag CutsceneTagSelected = EHazeLevelSequenceTag::Undefined;
	UPROPERTY()
	bool bShowDisabledSoundDefs = true;

	void Reset()
	{
		SelectedBankState = EBankLoadState::BankLoaded;
		bShowRTPCs = false;
		bShowAuxSends = false;
		bShowOverlappingEnvironments = false;
		bShowAttenuationScaling = false;
		bShowInactiveAudioComponents = false;
		bShowZonesAttenuation = true;
		ViewportScrollOffset = 0;
		CutsceneTagSelected = EHazeLevelSequenceTag::Undefined;
		bShowDisabledSoundDefs = true;
	}
}

struct FAudioDebugTypeFilters
{
	TArray<FString> Any;
	TArray<FString> All;
	TArray<FString> Exclusions;
}

struct FAudioDebugFilter
{
	UPROPERTY()
	TArray<FString> TextByType;

	// By feature request
	TArray<FAudioDebugTypeFilters> FiltersByType;
	// For UI visualization
	TArray<FString> TypeNames;

	TArray<FString> BoolOperators;

	FAudioDebugFilter()
	{
		BoolOperators.Add("or");
		BoolOperators.Add("and");
		BoolOperators.Add("not");

		SetEmptyFilters();
	}

	void PostLoad()
	{
		// Setup the filters
		for (int i=0; i < TextByType.Num(); ++i)
		{
			SetFilter(i, TextByType[i], true);
		}
	}

	void Reset()
	{
		for (int i=0; i < TextByType.Num(); ++i)
		{
			SetFilter(i, "");
		}
	}

	void SetEmptyFilters()
	{
		TextByType.SetNum(EDebugAudioFilter::Num);
		TypeNames.SetNum(EDebugAudioFilter::Num);
		FiltersByType.SetNum(EDebugAudioFilter::Num);

		for (int i=0; i < int(EDebugAudioFilter::Num); ++i)
		{
			TypeNames[i] = f"{EDebugAudioFilter(i) :n}";
		}
	}

	bool IsOperator(const FString& Value, FString& PreviousOperator, FString& OperatorToUse) const
	{
		for (int i=0; i<BoolOperators.Num(); ++i)
		{
			if (BoolOperators[i].Compare(Value, ESearchCase::IgnoreCase) == 0)
			{
				PreviousOperator = BoolOperators[i];
				return true;
			}
		}

		OperatorToUse = PreviousOperator;
		return false;
	}

	bool SetFilter(int i, const FString& NewFilter, bool bForce = false)
	{
		if (NewFilter == TextByType[i] && !bForce)
			return false;
		TextByType[i] = NewFilter;

		TArray<FString> Splits;
		TextByType[i].ParseIntoArray(Splits, " ", true);
		auto& TypeFilters = FiltersByType[i];

		TypeFilters.Exclusions.Reset();
		TypeFilters.Any.Reset();
		TypeFilters.All.Reset();

		if (Splits.Num() == 1)
		{
			TypeFilters.Any.Add(Splits[0]);
		}
		else
		{
			FString PreviousOperator = "";
			for (const auto Split: Splits)
			{
				FString Operator = "";
				if (IsOperator(Split, PreviousOperator, Operator))
				{
					continue;
				}

				if (Operator == "or")
				{
					TypeFilters.Any.Add(Split);
				}
				else if (Operator.IsEmpty() || Operator == "and")
				{
					TypeFilters.All.Add(Split);
				}
				else
				{
					TypeFilters.Exclusions.Add(Split);
				}
			}
		}

		return true;
	}

	const FString& GetFilterText(EDebugAudioFilter FilterType) const
	{
		check(TextByType.IsValidIndex(int(FilterType)));
		return TextByType[int(FilterType)];
	}

	void GetFilterRef(EDebugAudioFilter FilterType, FString& FilterRef, FAudioDebugTypeFilters& FiltersRef) const
	{
		check(TextByType.IsValidIndex(int(FilterType)));
		FilterRef = TextByType[int(FilterType)];
		FiltersRef = FiltersByType[int(FilterType)];
	}

	bool IsNameFiltered(EDebugAudioFilter FilterType, const FString& InName) const
	{
		FString FilterText;
		FAudioDebugTypeFilters Filters;
		GetFilterRef(FilterType, FilterText, Filters);

		if (FilterText.IsEmpty())
			return false;

		if (Filters.All.Num() > 0)
		{
			for (const auto& MustContain: Filters.All)
			{
				if (!InName.Contains(MustContain))
					return true;
			}
		}

		if (Filters.Exclusions.Num() > 0)
		{
			for (const auto& CantContain: Filters.Exclusions)
			{
				if (InName.Contains(CantContain))
					return true;
			}
		}

		if (Filters.Any.Num() > 0)
		{
			for (const auto& ContainAny: Filters.Any)
			{
				if (InName.Contains(ContainAny))
					return false;
			}

			return true;
		}

		return false;
	}
}
