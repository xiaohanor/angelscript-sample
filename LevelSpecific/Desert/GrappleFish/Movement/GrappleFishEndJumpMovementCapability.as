class UDesertGrappleFishEndJumpMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 40;

	ADesertGrappleFish GrappleFish;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;
	UCameraUserComponent CameraUser;

	float CurrentRoll;
	float CurrentBlend;

	FHazeAcceleratedFloat AccLandscapeHeight;

	FVector MoveDir;

	bool bHadMountedPlayer = false;

	AHazePlayerCharacter MountedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USimpleMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!GrappleFish.bTriggerEndJump)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!GrappleFish.bTriggerEndJump)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (GrappleFish.ControllingPlayer.IsMio())
			GrappleFish.AnimData.bTriggerMioEndJump = true;
		else
			GrappleFish.AnimData.bTriggerZoeEndJump = true;

		MountedPlayer = GrappleFish.MountedPlayer;
		GrappleFish.State.Apply(EDesertGrappleFishState::Mounted, this, EInstigatePriority::High);
		UDesertGrappleFishEventHandler::Trigger_OnStartSwimming(GrappleFish);
		AccLandscapeHeight.SnapTo(Desert::GetLandscapeHeightByLevel(GrappleFish.ActorLocation, GrappleFish.LandscapeLevel));
		MoveDir = GrappleFish.ActorForwardVector;
		UDesertGrappleFishEventHandler::Trigger_OnFinalJumpStarted(GrappleFish);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDesertGrappleFishEventHandler::Trigger_OnStopSwimming(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
		{
			return;
		}

		GrappleFish.AccMoveSpeed.AccelerateTo(GrappleFishMovement::EndJumpForwardMovementSpeed, GrappleFishMovement::EndJumpForwardAccelerationDuration, DeltaTime);
		float SplineHeight = GrappleFish.JumpSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(GrappleFish.ActorLocation).Z;
		if (HasControl())
		{
			FVector ForwardMoveDelta = GrappleFish.ActorForwardVector.VectorPlaneProject(FVector::UpVector) * GrappleFish.AccMoveSpeed.Value * DeltaTime;
			FVector UpwardMoveDelta = FVector::UpVector * (SplineHeight - GrappleFish.ActorLocation.Z);
			Movement.AddDelta(ForwardMoveDelta + UpwardMoveDelta);
		}

		MoveComp.ApplyMove(Movement);
	}
};