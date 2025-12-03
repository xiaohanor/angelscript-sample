
class UPlayerSwimmingSurfaceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingSurface);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 50;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerSwimmingComponent SwimmingComp;
	FHazeAcceleratedFloat AcceleratedSurfaceDistance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerSwimmingSurfaceData& SurfaceData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
			return false;

		if (SwimmingComp.GetState() != EPlayerSwimmingState::SurfaceDash && DeactiveDuration < SwimmingComp.Settings.SurfaceCooldown)
			return false;
		
		if (SwimmingComp.GetState() == EPlayerSwimmingState::ApexDive)
			return false;

		FPlayerSwimmingSurfaceData Data;
		if (!SwimmingComp.CheckForSurface(Player, Data))
			return false;
		
		//Check our vertical delta from surface
		if (!Player.IsCapabilityTagBlocked(n"SwimmingUnderwater") && Math::Abs(Data.DistanceToSurface) > SwimmingComp.Settings.SurfaceRangeFromUnderwater)
			return false;
		
		if (Data.DistanceToSurface > 0.0)
		{
			// Below surface
			if (Data.DistanceToSurface > SwimmingComp.Settings.SurfaceRangeFromUnderwater)
				return false;

			const float VerticalSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
			if (VerticalSpeed < 0.0)
				return false;
		}
		else
		{
			// Above surface
			if (Data.DistanceToSurface < -SwimmingComp.Settings.SurfaceRangeFromAboveSurface)
				return false;

			const float VerticalSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
			if (VerticalSpeed > 50.0)
				return false;

			if (!Player.IsCapabilityTagBlocked(n"SwimmingUnderwater") && VerticalSpeed < SwimmingComp.Settings.VerticalVelocityForUnderWaterSwim)
				return false;
		}

		SurfaceData = Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerSwimmingSurfaceData SurfaceData)
	{
		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SurfaceData.SurfaceLocation;

		if(SwimmingComp.GetState() != EPlayerSwimmingState::SurfaceDash)
			UPlayerSwimmingEffectHandler::Trigger_Surface_Started(Player, Data);

		switch (SwimmingComp.GetState())
		{
			case EPlayerSwimmingState::Inactive:
				UPlayerSwimmingEffectHandler::Trigger_Surface_Impacted(Player, Data);
				break;

			case EPlayerSwimmingState::Underwater:
				Data.BreachVelocity = MoveComp.Velocity;
				Data.BreachVerticalSpeed = MoveComp.WorldUp.DotProduct(MoveComp.Velocity);
					UPlayerSwimmingEffectHandler::Trigger_Surface_Breached(Player, Data);
				break;

			case EPlayerSwimmingState::Dive:
				break;

			default:
				break;
		}

		SwimmingComp.SurfaceData = SurfaceData;
		SwimmingComp.SetState(EPlayerSwimmingState::Surface);

		float VerticalSpeed = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
		AcceleratedSurfaceDistance.SnapTo(SwimmingComp.SurfaceData.DistanceToSurface, -VerticalSpeed);

		if(SwimmingComp.UnderwaterCamSettings != nullptr)
		{
			Player.ClearCameraSettingsByInstigator(SwimmingComp, 2);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;

		if((SwimmingComp.AnimData.State != EPlayerSwimmingState::Dive && SwimmingComp.AnimData.State != EPlayerSwimmingState::SurfaceDash))
			UPlayerSwimmingEffectHandler::Trigger_Surface_Stopped(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("SwimState", SwimmingComp.InstigatedSwimmingState.Get());
		TemporalLog.Value("AnimationState", SwimmingComp.AnimData.State);
		TemporalLog.Value("DistanceToSurface", SwimmingComp.SurfaceData.DistanceToSurface);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if (!Math::IsNearlyZero(ActiveDuration))
				{
					SwimmingComp.PreviousSurfaceData = SwimmingComp.SurfaceData;
					SwimmingComp.CheckForSurface(Player, SwimmingComp.SurfaceData);

					AcceleratedSurfaceDistance.SnapTo(SwimmingComp.SurfaceData.DistanceToSurface, AcceleratedSurfaceDistance.Velocity);
				}

				FVector Velocity = MoveComp.HorizontalVelocity;
				FVector TargetVelocity = MoveComp.MovementInput * SwimmingComp.Settings.SurfaceDesiredSpeed;

				//Enforce a minimum speed if giving input
				if(!MoveComp.MovementInput.IsNearlyZero() && TargetVelocity.Size() < SwimmingComp.Settings.SurfaceMinimumSpeed)
					TargetVelocity = TargetVelocity.GetSafeNormal() * SwimmingComp.Settings.SurfaceMinimumSpeed;

				Velocity = Math::VInterpTo(Velocity, TargetVelocity, DeltaTime, SwimmingComp.Settings.SurfaceDesiredSpeedInterpSpeed);
				Movement.AddVelocity(Velocity);

				AcceleratedSurfaceDistance.SpringTo(0.0, 60.0, 0.4, DeltaTime);
				float SurfaceDelta = SwimmingComp.SurfaceData.DistanceToSurface - AcceleratedSurfaceDistance.Value;
				Movement.AddDelta(MoveComp.WorldUp * SurfaceDelta);
				
				const FVector Impulses = MoveComp.GetPendingImpulse().ConstrainToPlane(MoveComp.WorldUp);
				Movement.AddVelocity(Impulses);

				// Rotate Player
				FRotator TargetRotation = Owner.ActorRotation;
				if (!MoveComp.MovementInput.IsNearlyZero())
					TargetRotation = FRotator::MakeFromXZ(MoveComp.HorizontalVelocity.GetSafeNormal(), MoveComp.WorldUp);
				Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 360.0));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

	
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SurfaceSwimming");
		}
	}

	
}