class UMoonMarketSausageAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;

	UPlayerMovementComponent MovementComponent;
	UPlayerAirMotionComponent AirMotionComponent;

	USteppingMovementData MoveData;

	UMoonMarketSausageMovementSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UPlayerMovementComponent::Get(Player);
		AirMotionComponent = UPlayerAirMotionComponent::Get(Owner);

		MoveData = MovementComponent.SetupSteppingMovementData();

		Settings = UMoonMarketSausageMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(MovementComponent.MovementInput, MovementComponent.HorizontalVelocity, DeltaTime);
				AirControlVelocity = AirControlVelocity.GetSafeNormal() * Math::Min(AirControlVelocity.Size(), Settings.ForwardSpeed);
				MoveData.AddHorizontalVelocity(AirControlVelocity);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();
				MoveData.AddPendingImpulses();

				FQuat Rotation = GetTargetRotation();
				float InterpSpeed = MovementComponent.MovementInput.Size() + KINDA_SMALL_NUMBER;
				MoveData.InterpRotationTo(Rotation, 10 * InterpSpeed, false);
				

				MoveData.RequestFallingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}
		}

		MovementComponent.ApplyMove(MoveData);
	}

	FQuat GetTargetRotation() const
	{
		FVector FacingDirection = FVector::ZeroVector;
		if (MovementComponent.MovementInput.IsNearlyZero())
			FacingDirection = Player.ActorForwardVector;
		else
			FacingDirection = MovementComponent.MovementInput;

		// Flip forward if heading the other way
		if (FacingDirection.DotProduct(Player.ActorForwardVector) < 0)
			FacingDirection = -FacingDirection;

		return FQuat::MakeFromX(FacingDirection);
	}
}