
class UPlayerSwimmingUnderWaterJumpOutOfCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingSurface);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingJump);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 40;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FPlayerSwimmingSurfaceData SurfaceData;
	float DeepestDepth = 0;
	float SwimUpTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!SwimmingComp.IsSwimming())
			return;
		
		FVector MovementInput;
		if(PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::SideScroller)
		{
			FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			MovementInput = Player.ViewRotation.RotateVector(FVector(0.0, MovementRaw.Y, MovementRaw.X));
		}

		if (((PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::ThirdPerson && IsActioning(ActionNames::MovementJump)) ||
			 (PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::SideScroller && MovementInput.DotProduct(MoveComp.WorldUp) > SwimmingComp.Settings.SideScrollerJumpOutDeadZone)) 
			 	&& SwimmingComp.Settings.UnderwaterJumpOutOfStrength > 0)
		{
			SwimUpTime += DeltaTime;
			if(SwimmingComp.CheckForSurface(Player, SurfaceData))
				DeepestDepth = Math::Max(SurfaceData.DistanceToSurface, DeepestDepth);
		}
		else
		{
			DeepestDepth = -1;
			SwimUpTime = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeepestDepth < SwimmingComp.Settings.SurfaceRangeFromUnderwater)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::ThirdPerson && !IsActioning(ActionNames::MovementJump))
			return false;

		FVector CurrentVelocity = Player.GetActorVelocity();
		float UpwardsVelocity = CurrentVelocity.DotProduct(Player.MovementWorldUp);
		if (UpwardsVelocity <= 1)
			return false;

		if (Math::Abs(SurfaceData.DistanceToSurface) > SwimmingComp.Settings.SurfaceRangeFromUnderwater)
			return false;

		if (SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
			return false;

		if (DeactiveDuration < SwimmingComp.Settings.SurfaceCooldown)
			return false;

		if (SwimUpTime <= SwimmingComp.Settings.UnderwaterSwimUpTimeRequiredForJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > 1)
			return true;

		if(Player.ActorVerticalVelocity.DotProduct(-Player.MovementWorldUp) >= 0)
			return true;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		FVector VerticalVelocity = MoveComp.WorldUp * SwimmingComp.Settings.UnderwaterJumpOutOfStrength;
		Player.SetActorVerticalVelocity(VerticalVelocity);
		Player.BlockCapabilities(PlayerMovementTags::Swimming, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Swimming, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float InterpSpeed = Math::Lerp(450.0, 1500.0, MoveComp.MovementInput.Size());
				FVector TargetSpeed = MoveComp.MovementInput * SwimmingComp.Settings.UnderwaterBreachjumpAirSpeed;
				FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, InterpSpeed);

				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();

				
				Movement.InterpRotationToTargetFacingRotation(UPlayerAirMotionSettings::GetSettings(Player).MaximumTurnRate);
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}	
	}
}