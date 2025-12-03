class UTundraPlayerTreeGuardianGroundedLifeGivingTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLifeGiving);

	UTundraPlayerShapeshiftingComponent PlayerShapeshiftingComponent;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	bool bTutorialPromptShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerShapeshiftingComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianLifeGivingTutorialActivatedParams& Params) const
	{
		if(PlayerShapeshiftingComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if(TreeGuardianComp.bEnteringLifeGiving || TreeGuardianComp.bCurrentlyLifeGiving)
			return false;

		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UTundraGroundedLifeReceivingTargetableComponent);
		if (PrimaryTarget == nullptr)
			return false;


		Params.LifeReceivingComp = UTundraLifeReceivingComponent::Get(PrimaryTarget.Owner);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerShapeshiftingComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return true;

		if(TreeGuardianComp.bEnteringLifeGiving || TreeGuardianComp.bCurrentlyLifeGiving)
			return true;

		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UTundraGroundedLifeReceivingTargetableComponent);
		if (PrimaryTarget == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianLifeGivingTutorialActivatedParams Params)
	{
		if(Params.LifeReceivingComp == nullptr)
			return;

		Player.ShowTutorialPrompt(Params.LifeReceivingComp.TutorialPromptWhenPossibleToLifeGive, this);
		bTutorialPromptShown = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bTutorialPromptShown)
			return;

		Player.RemoveTutorialPromptByInstigator(this);
		bTutorialPromptShown = false;
	}
}

struct FTundraPlayerTreeGuardianLifeGivingTutorialActivatedParams
{
	UTundraLifeReceivingComponent LifeReceivingComp;
}