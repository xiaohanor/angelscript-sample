UCLASS(Abstract, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags AssetUserData Navigation")
class UCenterViewTutorialPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Tap to Center")
	FTutorialPrompt TapToCenterTutorialPrompt;

	UPROPERTY(EditDefaultsOnly, Category = "Hold to Center")
	FTutorialPrompt HoldToCenterTutorialPrompt;

	UPROPERTY(EditDefaultsOnly, Category = "Soft Lock")
	FTutorialPrompt SoftLockTutorialPrompt;

	UPROPERTY(EditDefaultsOnly, Category = "Soft Lock")
	FTutorialPrompt SoftLockDisengageTutorialPrompt;

	UPROPERTY(EditDefaultsOnly, Category = "Hard Lock")
	FTutorialPrompt HardLockTutorialPrompt;

	UPROPERTY(EditDefaultsOnly, Category = "Hard Lock")
	FTutorialPrompt HardLockDisengageTutorialPrompt;

	private AHazePlayerCharacter Player;
	private UCenterViewPlayerComponent CenterViewComp;
	private TSet<FInstigator> ShowTutorialInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
	}

	void AddTutorialInstigator(FInstigator Instigator)
	{
		ShowTutorialInstigators.Add(Instigator);
	}

	void RemoveTutorialInstigator(FInstigator Instigator)
	{
		ShowTutorialInstigators.Remove(Instigator);
	}

	bool ShouldShowTutorial(bool bRequireInstigators) const
	{
		if(!CenterView::bAllowTutorials)
			return false;

		if(bRequireInstigators)
		{
			if(ShowTutorialInstigators.IsEmpty())
				return false;
		}

		if(!CenterViewComp.CanApplyCenterView())
			return false;

		if(!CenterViewComp.HasViewTarget())
			return false;

		if(!CenterViewComp.CurrentCenterViewTarget.Value.bShowTutorial)
			return false;

		return true;
	}
};