/**
 * Handles moving a foot to a new target location.
 */
class USkylineBossFootPlacementCapability : USkylineBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default CapabilityTags.Add(SkylineBossTags::SkylineBossFootPlacement);
	USkylineBossFootMovementComponent MoveComp;
	ESkylineBossLeg CurrentLeg;

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

		if(!MoveComp.CanStep())
			return false;

		if(Boss.IsStateActive(ESkylineBossState::Fall))
			return false;

		float TimeSinceLastMove = Time::GetGameTimeSince(MoveComp.LastFootPlacementTimestamp);
		if (TimeSinceLastMove < Boss.Settings.StepInterval)
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
		CurrentLeg = MoveComp.NewStep();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CanStep())
		{
			CurrentLeg = MoveComp.NewStep();
		}

		MoveComp.HandleFootMovement(CurrentLeg, DeltaTime);
	}

	bool CanStep() const
	{
		auto& MovementData = Boss.MovementQueue[0];
		
		if (MovementData.CurrentStep == 0)
			return true;

		const float TimeSinceFootPlacement = Time::GetGameTimeSince(MoveComp.LastFootPlacementTimestamp);
		return TimeSinceFootPlacement > Boss.Settings.StepInterval && MoveComp.CanStep() && MoveComp.FeetMovementData[CurrentLeg].LegComponent.bIsGrounded;
	}
}