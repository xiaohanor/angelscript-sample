class USkylineCrowdSurfingLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 99;

	USkylineCrowdSurfingUserComponent UserComp;
	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineCrowdSurfingUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.IsCrowdSurfing)
			return false;

		if (!IsActioning(ActionNames::MovementJump))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.HasLeftCrowd())
			return true;

		return false;
/*
		if (!UserComp.IsCrowdSurfing)
			return true;

		if (!IsActioning(ActionNames::MovementJump))
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
*/
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = 0.5;
		Settings.bLoop = true;
		Settings.PlayRate = 2.0;

		Owner.PlaySlotAnimation(UserComp.SurfAnim, Settings);

		Player.SetActorVerticalVelocity(FVector::UpVector * 2000.0);

//		Player.AddMovementImpulse(FVector::UpVector * 5000.0);

		PrintToScreen("CrowdLaunch!", 0.5, FLinearColor::Green);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.StopSlotAnimationByAsset(UserComp.SurfAnim, 0.5);

//		Player.AddMovementImpulse(FVector::UpVector * 1000.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
/*
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Input = MoveComp.MovementInput;

				FVector Velocity = MoveComp.Velocity;

				FVector Acceleration = MoveComp.Gravity
									 + Input * UserComp.MovementForce
									 + UserComp.PushForce
									 - Velocity * UserComp.CrowdDrag;

				Velocity += Acceleration * DeltaTime;
				Velocity = FVector::UpVector * 1000.0;

				Movement.AddVelocity(Velocity);
				Movement.InterpRotationTo(Input.ToOrientationQuat(), 1.0);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
*/
	}
};