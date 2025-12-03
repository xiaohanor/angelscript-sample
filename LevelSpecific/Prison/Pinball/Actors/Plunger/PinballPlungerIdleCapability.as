class UPinballPlungerIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 70;

	APinballPlunger Plunger;

	FHazeAcceleratedFloat AccPlungerDistanceIdle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plunger = Cast<APinballPlunger>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Plunger.HasAppliedLocationThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Plunger.HasAppliedLocationThisFrame())
			return true;

		// Some other capability changed state, this generally shouldn't happen
		if(Plunger.State != EPinballPlungerState::Idle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Plunger.State = EPinballPlungerState::Idle;
		Plunger.BlockFollowComp.ApplyBlockFollow(false, this);

		AccPlungerDistanceIdle.SnapTo(Plunger.PlungerDistance, Plunger.PlungerSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Plunger.BlockFollowComp.ClearBlockFollow(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Plunger.PlungerSpeed = 0;
		if(Plunger.bSpringBackToIdle)
		{
			// Use accelerated float to spring towards the target. Inherits velocity from the transition.
			Plunger.PlungerDistance = AccPlungerDistanceIdle.SpringTo(0, Plunger.IdleReturnSpringStiffness, Plunger.IdleReturnSpringDamping, DeltaTime);
		}
		else
		{
			// Use accelerated float to smoothly accelerate towards the target. Inherits velocity from the transition.
			Plunger.PlungerDistance = AccPlungerDistanceIdle.AccelerateTo(0, Plunger.IdleReturnDuration, DeltaTime);
		}

		Plunger.ApplyLocation();
	}

	bool ShouldSleep() const
	{
		if(AccPlungerDistanceIdle.Value > KINDA_SMALL_NUMBER || AccPlungerDistanceIdle.Value < -KINDA_SMALL_NUMBER)
			return false;

		if(AccPlungerDistanceIdle.Velocity > KINDA_SMALL_NUMBER || AccPlungerDistanceIdle.Velocity < -KINDA_SMALL_NUMBER)
			return false;

		return true;
	}
};