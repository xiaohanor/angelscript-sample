class USkylineCrowdSurfingMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

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

		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.IsCrowdSurfing)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = 0.5;
		Settings.bLoop = true;
		Settings.PlayRate = 2.0;

		Owner.PlaySlotAnimation(UserComp.SurfAnim, Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.StopSlotAnimationByAsset(UserComp.SurfAnim, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
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

				Movement.AddVelocity(Velocity);
				Movement.InterpRotationTo(Input.ToOrientationQuat(), 2.0);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
};