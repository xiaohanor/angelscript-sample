class UTundraPlayerTreeGuardianGroundedLifeGivingFoundTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLifeGiving);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Input;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UTundraGroundedLifeReceivingTargetableComponent CurrentFrameTargetable;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CurrentFrameTargetable = PlayerTargetablesComp.GetPrimaryTarget(UTundraGroundedLifeReceivingTargetableComponent);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianGroundedLifeGivingFoundTargetActivatedParams& Params) const
	{
		if(CurrentFrameTargetable == nullptr)
			return false;

		Params.Targetable = CurrentFrameTargetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CurrentFrameTargetable == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianGroundedLifeGivingFoundTargetActivatedParams Params)
	{
		FoundTarget(Params.Targetable);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LostTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CurrentFrameTargetable != TreeGuardianComp.CurrentlyFoundGroundedLifeReceivingTargetable)
		{
			ChangeTarget(CurrentFrameTargetable);
		}
	}

	void ChangeTarget(UTundraGroundedLifeReceivingTargetableComponent NewTargetable)
	{
		LostTarget();
		FoundTarget(NewTargetable);
	}

	void FoundTarget(UTundraGroundedLifeReceivingTargetableComponent Targetable)
	{
		TreeGuardianComp.CurrentlyFoundGroundedLifeReceivingTargetable = Targetable;
		TreeGuardianComp.CurrentlyFoundGroundedLifeReceivingTargetable.OnFoundTarget.Broadcast();
	}

	void LostTarget()
	{
		// This can be null when loading a new level.
		if(TreeGuardianComp.CurrentlyFoundGroundedLifeReceivingTargetable == nullptr)
			return;

		TreeGuardianComp.CurrentlyFoundGroundedLifeReceivingTargetable.OnLostTarget.Broadcast();
		TreeGuardianComp.CurrentlyFoundGroundedLifeReceivingTargetable = nullptr;
	}
}

struct FTundraPlayerTreeGuardianGroundedLifeGivingFoundTargetActivatedParams
{
	UTundraGroundedLifeReceivingTargetableComponent Targetable;
}