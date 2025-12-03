class USkylineInnerCityHitSwingAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	ASkylineInnerCityHitSwing SwingThing;

	UHazeMovementComponent MoveComp;
	USkylineInnerCityHitSwingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingThing = Cast<ASkylineInnerCityHitSwing>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupMovementData(USkylineInnerCityHitSwingMovementData);
		Movement.SetIsClampedToPlane(false);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingThing.bFalling = true;
		USkylineInnerCityHitSwingEventHandler::Trigger_OnLostRoofConnection(SwingThing);

		MoveComp.OverrideGravityDirection(FMovementGravityDirection::TowardsDirection(FVector::DownVector), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingThing.bFalling = false;
		MoveComp.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement, SwingThing.ActorUpVector))
			return;

		if (HasControl())
		{
			Movement.SetIsClampedToPlane(false);

			// Apply gravity
			Movement.AddGravityAcceleration();
			Movement.AddOwnerVelocity();

			// Add any impulses that were added from being hit
			Movement.AddPendingImpulses();
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};