namespace LiftSection
{
	ULiftSectionManagerComponent GetManager()
	{
		ULiftSectionManagerComponent Manager = ULiftSectionManagerComponent::Get(Game::Mio);
		
		if(Manager == nullptr)
			Manager = ULiftSectionManagerComponent::Create(Game::Mio);

		return Manager;
	}

	UFUNCTION(BlueprintPure, DisplayName = "Get Lift Section Manager")
	ULiftSectionManagerComponent BP_GetLiftSectionManager()
	{
		return GetManager();
	}

	UFUNCTION(BlueprintCallable)
	void AddLevelStateInstigatorDoingStuff(FInstigator Source)
	{
		LiftSection::GetManager().AddLevelStateInstigatorDoingStuff(Source);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveLevelStateInstigatorDoingStuff(FInstigator Source)
	{
		LiftSection::GetManager().RemoveLevelStateInstigatorDoingStuff(Source);
	}

	UFUNCTION(BlueprintPure)
	ELiftSectionLevelState GetLiftSectionLevelState()
	{
		return LiftSection::GetManager().GetLevelState();
	}

	UFUNCTION(BlueprintCallable)
	void SetInLevelState(ELiftSectionLevelState LevelState)
	{
		LiftSection::GetManager().SetInLevelState(LevelState);
	}

	UFUNCTION(BlueprintCallable)
	void SetLevelStateDone(ELiftSectionLevelState LevelState)
	{
		LiftSection::GetManager().SetLevelStateDone(LevelState);
	}
}