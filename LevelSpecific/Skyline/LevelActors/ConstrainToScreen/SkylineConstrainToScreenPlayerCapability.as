
asset USkylineConstrainToScreenPlayerSheet of UHazeCapabilitySheet
{
	AddCapability(n"SkylineConstrainToScreenPlayerCapability");
};

class USkylineConstrainToScreenPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	USkylineConstrainToScreenPlayerComponent ConstrainComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		ConstrainComp = USkylineConstrainToScreenPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ConstrainComp.GetIsConstrainedHorizontal())
			return true;

		if(ConstrainComp.GetIsConstrainedVertical())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const	
	{
		if(ConstrainComp.GetIsConstrainedHorizontal())
			return false;

		if(ConstrainComp.GetIsConstrainedVertical())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.OverrideResolver(USkylineConstrainToScreenMovementResolver, this, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(USkylineConstrainToScreenMovementResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ConstrainComp.GetRequestedKillPlayer())
		{
			ConstrainComp.SetRequestedKillPlayer(false);
			Player.KillPlayer();
		}
	}
};