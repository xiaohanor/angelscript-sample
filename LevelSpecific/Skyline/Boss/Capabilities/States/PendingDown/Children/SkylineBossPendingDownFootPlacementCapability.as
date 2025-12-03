

/**
 * Handles moving multiple feet at the same time.
 */
class USkylineBossPendingDownFootPlacementCapability : USkylineBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default CapabilityTags.Add(SkylineBossTags::SkylineBossFootPlacement);

	USkylineBossFootMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = USkylineBossFootMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boss.bCanWalk)
			return false;

		if (Boss.MovementQueue.IsEmpty())
			return false;

		if(Boss.IsStateActive(ESkylineBossState::Fall))
			return false;

		if(!MoveComp.CanStep())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.MovementQueue.IsEmpty())
			return true;

		if(Boss.IsStateActive(ESkylineBossState::Fall))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.NewStep();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeSinceFootLift = Time::GetGameTimeSince(MoveComp.LastStepTimeStamp);
		if (TimeSinceFootLift > Boss.Settings.StepInterval && MoveComp.CanStep())
		{
			MoveComp.NewStep();
		}

		for(auto Foot : MoveComp.FeetMovementData)
		{
			if(Foot.Value.LegComponent.bIsGrounded)
				continue;
			
			MoveComp.HandleFootMovement(Foot.Key, DeltaTime);
		}
	}
}