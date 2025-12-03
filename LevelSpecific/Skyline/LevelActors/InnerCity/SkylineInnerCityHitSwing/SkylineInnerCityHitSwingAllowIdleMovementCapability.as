class USkylineInnerCityHitSwingAllowIdleMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASkylineInnerCityHitSwing SwingThing;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingThing = Cast<ASkylineInnerCityHitSwing>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (WasRecentlyHit())
			return false;
		if (MoveComp.HorizontalVelocity.Size() > 10.0)
			return false;
		if (!HasSplines())
			return false;
		return true;
	}

	bool HasSplines() const
	{
		if (SwingThing.StartMoveSpline == nullptr)
			return false;
		if (SwingThing.IdleMoveSpline1 == nullptr)
			return false;
		if (SwingThing.IdleMoveSpline2 == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WasRecentlyHit())
			return true;
		return false;
	}

	bool WasRecentlyHit() const
	{
		return SwingThing.LastHitTime + InnerCityHitSwing::DelayUntilMoveAgainAfterHit > Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingThing.bAllowIdleMovement = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingThing.bAllowIdleMovement = false;
	}
};