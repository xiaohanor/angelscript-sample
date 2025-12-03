
class UPlayerSwimmingSurfaceDiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingSurface);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingDive);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 25;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	const float DiveDuration = 0.6;
	const float DiveDistance = 120.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
			return false;

		if (SwimmingComp.AnimData.State != EPlayerSwimmingState::Surface)
			return false;

		if (PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::ThirdPerson && !IsActioning(ActionNames::MovementVerticalDown))
			return false;
		
		if (PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller && !VerifyDiveInputThreshhold())
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

		if (SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return true;

		if (ActiveDuration >= DiveDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwimmingComp.SetState(EPlayerSwimmingState::Dive);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;
		UPlayerSwimmingEffectHandler::Trigger_Surface_Dive(Player, Data);
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
				FVector TargetVelocity = MoveComp.MovementInput * SwimmingComp.Settings.DiveDesiredHorizontalSpeed;
				FVector HorizontalVelocity = Math::VInterpTo(MoveComp.HorizontalVelocity, TargetVelocity, DeltaTime, SwimmingComp.Settings.DiveDesiredHorizontalSpeedInterpSpeed);
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				FVector VerticalVelocity = MoveComp.VerticalVelocity;
				VerticalVelocity -= MoveComp.WorldUp * SwimmingComp.Settings.DiveStrength * DeltaTime;
				Movement.AddVerticalVelocity(VerticalVelocity);

				// Rotate Player
				FRotator TargetRotation = Owner.ActorRotation;
				if (!MoveComp.MovementInput.IsNearlyZero())
				{
					TargetRotation = FRotator::MakeFromXZ(MoveComp.MovementInput, MoveComp.WorldUp);
					TargetRotation.Pitch = 0.0;
				}
				Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 360.0));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Swimming");
		}
	}

	bool VerifyDiveInputThreshhold() const
	{
		FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector MoveDirection = Player.ViewRotation.RotateVector(FVector(
						0.0, RawInput.Y, RawInput.X,
					));
		
		float VerticalDotThreshhold = MoveDirection.DotProduct(-MoveComp.WorldUp);
		
		if(VerticalDotThreshhold < SwimmingComp.Settings.SideScrollerDiveDeadZone)
			return false;

		return true;
	}
}