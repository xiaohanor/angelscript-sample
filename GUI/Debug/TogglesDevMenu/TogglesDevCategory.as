struct FHazeDevToggleCategory
{
	FName CategoryName;

	FHazeDevToggleCategory(FName Name)
	{
		CategoryName = Name;
	}

	void MakeVisible() const
	{
#if !RELEASE
		TArray<FName> TogglePathsInCategory = DevMenu::GetTogglesInCategory(CategoryName);
		for (FName& Path : TogglePathsInCategory)
			UHazeDevToggleSubsystem::Get().MakeCategoryToggleVisible(Path);
		UHazeDevToggleSubsystem::Get().bDirty = true;
#endif	
	}
};