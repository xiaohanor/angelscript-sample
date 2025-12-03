
class UTundraPlayerOtterSwimmingSurfaceJumpCapability : UHazePlayerCapability
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
	UTundraPlayerOtterSwimmingComponent SwimmingComp;

	const float JumpDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		SwimmingComp = UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() != ETundraPlayerOtterSwimmingActiveState::Active)
			return false;

		if (SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::Surface)
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

		if(ActiveDuration > JumpDuration)
			return true;

		if(Player.ActorVerticalVelocity.DotProduct(-Player.MovementWorldUp) >= 0)
			return true;

		if(!MoveComp.IsInAir() && (!MoveComp.HasCustomMovementStatus(n"Swimming") && ActiveDuration <= (JumpDuration * 0.33)))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// SwimmingComp.AnimData.State = ETundraPlayerOtterSwimmingState::Jump;

		FVector VerticalVelocity = MoveComp.WorldUp * SwimmingComp.Settings.SurfaceJumpOutOfStrength;
		Player.SetActorVerticalVelocity(VerticalVelocity);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;
		UPlayerSwimmingEffectHandler::Trigger_Surface_JumpedOut(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

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
				Movement.RequestFallingForThisFrame();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}
	}
}