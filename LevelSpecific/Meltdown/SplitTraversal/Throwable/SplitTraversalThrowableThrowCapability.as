class USplitTraversalThrowableThrowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;

	USplitTraversalThrowablePlayerComponent ThrowableComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	ASplitTraversalThrowable Throwable;
	bool bThrown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThrowableComp = USplitTraversalThrowablePlayerComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ThrowableComp.HeldThrowable == nullptr)
			return false;
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bThrown = false;
		Throwable = ThrowableComp.HeldThrowable;
		Throwable.bIsThrowInitiated = true;

		// Add CameraImpulse
		FHazeCameraImpulse CameraImpulse;
		CameraImpulse.CameraSpaceImpulse = FVector::ForwardVector * -400.0;
		CameraImpulse.AngularImpulse = FRotator(80.0, 0.0, 0.0);
		CameraImpulse.ExpirationForce = 64.0;
		Player.ApplyCameraImpulse(CameraImpulse, this);
	
		// Play ThrowAnimation
		Player.PlaySlotAnimation(Animation = Throwable.ThrowAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Throwable.bIsThrowInitiated = false;
		ThrowableComp.HeldThrowable = nullptr;
		Throwable = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 0.5 && !bThrown)
		{
			Throwable.DetachRootComponentFromParent();
			Throwable.StartThrowing();
			bThrown = true;
		}

		if (ActiveDuration < 0.5)
		{
			if (MoveComp.PrepareMove(Movement))
			{
				if (Player.IsMio())
					Movement.SetRotation(FRotator::MakeFromZX(MoveComp.WorldUp, Player.ViewRotation.RightVector));
				else
					Movement.SetRotation(FRotator::MakeFromZX(MoveComp.WorldUp, -Player.ViewRotation.RightVector));
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
			}
		}
	}
};