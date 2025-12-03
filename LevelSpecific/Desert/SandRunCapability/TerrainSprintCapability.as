class UTerrainSprintCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	UPlayerStepDashComponent DashComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		DashComp = UPlayerStepDashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasGroundContact())
			return false;

		if (MoveComp.GroundContact.Actor != nullptr)
		{
			if (MoveComp.GroundContact.Actor.Class != ALandscape)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ForceSprint(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearForceSprint(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};