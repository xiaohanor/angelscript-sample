class UPigJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::GroundJump);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40; // Tick before player jump

	default DebugCategory = PigTags::Pig;

	UPlayerPigComponent PigComponent;
	UPlayerAirMotionComponent AirMotionComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	const float JumpDuration = 0.7;

	bool bIsinJumpGracePeriod = false;
	float JumpGraceTimer = 0.0;
	float GraceTime = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigComponent = UPlayerPigComponent::Get(Owner);
		AirMotionComponent = UPlayerAirMotionComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MovementComponent.IsInAir())
		{
			JumpGraceTimer += DeltaTime;
			bIsinJumpGracePeriod = JumpGraceTimer <= GraceTime;
		}
		else if (MovementComponent.IsOnAnyGround())
		{
			JumpGraceTimer = 0.0;
			bIsinJumpGracePeriod = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnWalkableGround() && !bIsinJumpGracePeriod)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::MovementJump, 0.4))
			return false;

		// Add little delay to play nice with animation (no spamming!)
		float GroundedTime = Time::GameTimeSeconds - MovementComponent.GetFallingData().EndTime;
		if (GroundedTime < 0.2)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (MovementComponent.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Inherit velocity
		FVector InitialHorizontalVelocity, InitialVerticalVelocity;
		GetInheritedGroundVelocity(InitialHorizontalVelocity, InitialVerticalVelocity);

		// Add impulse and set velocity
		InitialHorizontalVelocity += CalculateInitialHorizontalVelocity();
		InitialVerticalVelocity += MovementComponent.WorldUp * UPigMovementSettings::GetSettings(Player).JumpImpulse;
		Player.SetActorHorizontalAndVerticalVelocity(InitialHorizontalVelocity, InitialVerticalVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

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

				MoveData.InterpRotationToTargetFacingRotation(UPlayerJumpSettings::GetSettings(Player).FacingDirectionInterpSpeed * MovementComponent.MovementInput.Size());

				MoveData.RequestFallingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(GetLocomotionTag(), this);
	}

	void GetInheritedGroundVelocity(FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(MovementComponent.GroundContact.IsValidBlockingHit())
		{
			if(MovementComponent.GroundContact.Actor != nullptr)
			{
				UPlayerInheritVelocityComponent VelocityComponent = Cast<UPlayerInheritVelocityComponent>(MovementComponent.GroundContact.Actor.GetComponent(UPlayerInheritVelocityComponent));
				if(VelocityComponent != nullptr)
					VelocityComponent.AddFollowAdjustedVelocity(MovementComponent, HorizontalVelocity, VerticalVelocity);
			}
		}
	}

	FVector CalculateInitialHorizontalVelocity() const
	{
		return MovementComponent.HorizontalVelocity.GetSafeNormal() * Math::Max(AirMotionComponent.Settings.HorizontalMoveSpeed * MovementComponent.MovementInput.Size(), MovementComponent.HorizontalVelocity.Size());
	}

	FName GetLocomotionTag() const
	{
		if (ActiveDuration < JumpDuration)
			return n"Jump";

		return n"AirMovement";
	}
}