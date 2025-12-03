namespace GentlemanStatics
{
	UFUNCTION(BlueprintCallable)
	void SetInvalidTarget(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		UGentlemanComponent GentComp = UGentlemanComponent::Get(Player);
		if(GentComp == nullptr)
			return;
		GentComp.SetInvalidTarget(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void ClearInvalidTarget(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		UGentlemanComponent GentComp = UGentlemanComponent::Get(Player);
		if(GentComp == nullptr)
			return;
		GentComp.ClearInvalidTarget(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	bool IsValidTarget(AHazePlayerCharacter Player)
	{
		UGentlemanComponent GentComp = UGentlemanComponent::Get(Player);
		if(GentComp == nullptr)
			return true;
		return GentComp.IsValidTarget();
	}
}