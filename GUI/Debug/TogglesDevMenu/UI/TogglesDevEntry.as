struct FHazeDevToggleEntry
{
	TArray<FString> PathNodes;

	FName Category;
	FName Subcategory;
	FName WholePath;
	FHazeInternalDevToggleBool BoolData;
	FHazeInternalDevToggleGroup GroupData;

	int FilterScore = 0;
	bool bIsSubcategory = false;
	bool bIsMaincategory = false;

	FHazeDevToggleEntry(FHazeInternalDevToggleGroup& Data, FName Path)
	{
		GroupData = Data;
		WholePath = Path;
		PathNodes.Reset(3);
		Path.ToString().ParseIntoArray(PathNodes, "/");
		Category = FName(PathNodes[0]);
		if (PathNodes.Num() == 3)
			Subcategory = FName(PathNodes[1]);
	}

	FHazeDevToggleEntry(FHazeInternalDevToggleBool& Data, FName Path)
	{
		BoolData = Data;
		WholePath = Path;
		PathNodes.Reset(3);
		Path.ToString().ParseIntoArray(PathNodes, "/");
		Category = FName(PathNodes[0]);
		if (PathNodes.Num() == 3)
			Subcategory = FName(PathNodes[1]);
	}

	void AssignFuzzyScore(const TArray<FString>& FilterTerms)
	{
		FilterScore = 0;
		if (FilterTerms.Num() == 0)
			return;

		FString& TreeLeaf = PathNodes.Last();
		FString& TreeCategory = PathNodes[0];
		bool bHasSubcategory = PathNodes.Num() == 3;

		float ScoreMultiplier = 1.5 / WholePath.ToString().Len();
		for (int i = 0; i < FilterTerms.Num(); ++i)
		{
			const FString& FilterTerm = FilterTerms[i];
			// Leaf score
			{
				ScoreMultiplier = 1.5;
				FilterScore += GetScore(TreeLeaf, ScoreMultiplier, FilterTerm);
			}
			// Subcategory score
			if (bHasSubcategory)
			{
				ScoreMultiplier = 1.1;
				FilterScore += GetScore(PathNodes[1], ScoreMultiplier, FilterTerm);
			}
			// Category score
			{
				ScoreMultiplier = 1.0;
				FilterScore += GetScore(TreeCategory, ScoreMultiplier, FilterTerm);
			}
		}
	}

	int GetScore(FString& PathPart, float Multiplier, const FString & FilterTerm)
	{
		float Score = 0.0;
		if (PathPart == FilterTerm)
			Score = 1000.0;
		else
		{
			// todo
			if (PathPart.Contains(FilterTerm))
				Score += 10.0;
		}
		return Math::FloorToInt(Score * Multiplier);
	}

	private int SortaAlphabeticalCompare(const FHazeDevToggleEntry& Other) const
	{
		if (Category != Other.Category)
		{
			bool bIsGeneric = UHazeDevToggleSubsystem::Get().IsGenericCategory(Category);
			bool bOtherIsGeneric = UHazeDevToggleSubsystem::Get().IsGenericCategory(Other.Category);
			if (bIsGeneric != bOtherIsGeneric)
			{
				if (bIsGeneric)
					return -1;
				if (bOtherIsGeneric)
					return 1;
			}
			return Other.Category.Compare(Category);
		}

		if (bIsMaincategory)
			return 1;
		if (Other.bIsMaincategory)
			return -1;

		if (Subcategory.IsNone() && !Other.Subcategory.IsNone())
			return 1;
		if (!Subcategory.IsNone() && Other.Subcategory.IsNone())
			return -1;

		if (Other.Subcategory != Subcategory)
			return Other.Subcategory.Compare(Subcategory);
		if (bIsSubcategory)
			return 1;
		if (Other.bIsSubcategory)
			return -1;

		bool bHasOptions = GroupData.Options.Num() > 0;
		bool bOtherHasOptions = Other.GroupData.Options.Num() > 0;
		if (!bHasOptions && bOtherHasOptions)
			return -1;
		if (bHasOptions && !bOtherHasOptions)
			return 1;

		return Other.PathNodes.Last().Compare(PathNodes.Last());
	}

	int opCmp(const FHazeDevToggleEntry& Other) const
	{
		if (FilterScore < Other.FilterScore)
			return -1;
		else if (FilterScore > Other.FilterScore)
			return 1;
		return SortaAlphabeticalCompare(Other);
	}
}
