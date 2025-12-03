
class UPlayerSwimmingSurfaceJumpCapability : UHazePlayerCapability
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
	default TickGroupSubPlacement = 15;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerAirJumpComponent AirJumpComp;

	const float DiveDuration = 0.6;
	const float DiveDistance = 120.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		AirJumpComp = UPlayerAirJumpComponent::GetOrCreate(Player);
		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
			return false;

		if (SwimmingComp.State != EPlayerSwimmingState::Surface)
			return false;

		if (!Math::IsNearlyZero(SwimmingComp.SurfaceData.DistanceToSurface, SwimmingComp.Settings.UnderwaterWaterRangeFromSurface))
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

		if(MoveComp.HasCustomMovementStatus(n"Swimming"))
			return false;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// SwimmingComp.AnimData.State = EPlayerSwimmingState::Jump;

		FVector VerticalVelocity = MoveComp.WorldUp * SwimmingComp.Settings.SurfaceJumpOutOfStrength;
		Player.SetActorVerticalVelocity(VerticalVelocity);

		// AirJumpComp.bPerformedDoubleJump = true;

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;
		UPlayerSwimmingEffectHandler::Trigger_Surface_JumpedOut(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// AirJumpComp.bPerformedDoubleJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float InterpSpeed = Math::Lerp(450.0, 1500.0, MoveComp.MovementInput.Size());
				FVector TargetSpeed = MoveComp.MovementInput * 600.0;
				FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, InterpSpeed);

				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();

				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
		}
		
		Movement.RequestFallingForThisFrame();
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
	}
}