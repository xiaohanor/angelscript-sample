class UPigSausageAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;
	default DebugCategory = PigTags::Pig;

	UPlayerPigSausageComponent SausageComponent;
	UPlayerMovementComponent MovementComponent;
	UPlayerAirMotionComponent AirMotionComponent;

	USteppingMovementData MoveData;

	UPigSausageMovementSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SausageComponent = UPlayerPigSausageComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		AirMotionComponent = UPlayerAirMotionComponent::Get(Owner);

		MoveData = MovementComponent.SetupSteppingMovementData();

		Settings = UPigSausageMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SausageComponent.IsSausageActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SausageComponent.IsSausageActive())
			return true;

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
				MoveData.AddHorizontalVelocity(AirControlVelocity);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();
				MoveData.AddPendingImpulses();

				if(SausageComponent.GetCurrentMovement() == EPigSausageMovementType::Floppy)
				{
					FQuat Rotation = GetTargetRotation();
					float InterpSpeed = MovementComponent.MovementInput.Size() + KINDA_SMALL_NUMBER;
					MoveData.InterpRotationTo(Rotation, 10 * InterpSpeed, false);
				}
				else
				{
					MoveData.InterpRotationToTargetFacingRotation(UPlayerJumpSettings::GetSettings(Player).FacingDirectionInterpSpeed * MovementComponent.MovementInput.Size());
				}

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