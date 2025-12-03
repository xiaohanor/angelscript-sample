UCLASS(Abstract)
class UMagnetDroneTutorialComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FTutorialPrompt TutorialPrompt;

	TSet<FInstigator> ShowTutorialInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneTutorial");
#endif
	}

	bool ShouldShowTutorial() const
	{
		return !ShowTutorialInstigators.IsEmpty();
	}
};

UFUNCTION(BlueprintCallable, Category = "Magnet Drone")
void ShowMagnetDroneTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
{
	if(Player.IsMio())
	{
		PrintWarning("Can't start magnet tutorial on Mio lol");
		return;
	}

	auto TutorialComp = UMagnetDroneTutorialComponent::Get(Player);
	if(TutorialComp == nullptr)
	{
		PrintWarning("Can't start magnet tutorial on player because the sheet is missing!");
		return;
	}

	TutorialComp.ShowTutorialInstigators.Add(Instigator);
}

UFUNCTION(BlueprintCallable, Category = "Magnet Drone")
void RemoveMagnetDroneTutorial(AHazePlayerCharacter Player, FInstigator Instigator)
{
	if(Player.IsMio())
		return;

	auto TutorialComp = UMagnetDroneTutorialComponent::Get(Player);
	if(TutorialComp == nullptr)
		return;

	TutorialComp.ShowTutorialInstigators.Remove(Instigator);
}