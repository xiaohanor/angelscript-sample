struct FGiantHornBlowAvailableActivationParams
{
	AGiantHorn Horn;
}

class UGiantHornBlowAvailableCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AGiantHorn Horn;

	UPlayerInteractionsComponent InteractionsComp;
	UPlayerTeenDragonComponent DragonComp;

	float AnimDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGiantHornBlowActivationParams& Params) const
	{
		if(InteractionsComp.ActiveInteraction == nullptr)
			return false;
		
		AGiantHorn InteractHorn = Cast<AGiantHorn>(InteractionsComp.ActiveInteraction.Owner);
		if(InteractHorn == nullptr)
			return false;

		float TimeSinceLastBlewIntoHorn = Time::GetGameTimeSince(InteractHorn.TimeLastBlewIntoHorn);
		if(TimeSinceLastBlewIntoHorn < InteractHorn.CooldownTime)
			return false;

		Params.Horn = InteractHorn;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Horn.bIsBlowingIntoHorn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGiantHornBlowActivationParams Params)
	{
		Horn = Params.Horn;

		FTutorialPrompt BlowTutorial;
		BlowTutorial.Action = ActionNames::PrimaryLevelAbility;
		BlowTutorial.DisplayType = ETutorialPromptDisplay::Action;
		BlowTutorial.Text = NSLOCTEXT("Summit Giant Horn", "Blow Tutorial", "Roar");
		Player.ShowTutorialPromptWorldSpace(BlowTutorial, this, Horn.PromptAttach, FVector(0.0), 0.0);

		Horn.bBlowAvailable = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
};