
class UTundraPlayerOtterSwimmingSurfaceCapability : UHazePlayerCapability
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

	UTundraPlayerOtterSwimmingComponent SwimmingComp;
	FHazeAcceleratedFloat AcceleratedSurfaceDistance;
	FVector VerticalImpulseVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		SwimmingComp = UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerOtterSwimmingSurfaceData& SurfaceData) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() != ETundraPlayerOtterSwimmingActiveState::Active)
			return false;
		
		if(SwimmingComp.Settings.bForceSurfaceSwimming)
		{
			FTundraPlayerOtterSwimmingSurfaceData Data;
			if (!SwimmingComp.CheckForSurface(Player, Data))
				return false;

			SurfaceData = Data;
			return true;
		}

		if (SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::SurfaceDash && DeactiveDuration < SwimmingComp.Settings.SurfaceCooldown)
			return false;
		
		FTundraPlayerOtterSwimmingSurfaceData Data;
		if (SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::SurfaceDash && !SwimmingComp.CheckForSurface(Player, Data))
			return false;
		
		//Check our vertical delta from surface
		if (Math::Abs(Data.DistanceToSurface) > SwimmingComp.Settings.SurfaceRangeFromUnderwater)
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
			if (VerticalSpeed > 0.0)
				return false;

			if (VerticalSpeed < SwimmingComp.Settings.VerticalVelocityForUnderWaterSwim)
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

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() == ETundraPlayerOtterSwimmingActiveState::Inactive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerOtterSwimmingSurfaceData SurfaceData)
	{
		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SurfaceData.SurfaceLocation;

		if(SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::SurfaceDash)
			UPlayerSwimmingEffectHandler::Trigger_Surface_Started(Player, Data);

		switch (SwimmingComp.CurrentState)
		{
			case ETundraPlayerOtterSwimmingState::Inactive:
				UPlayerSwimmingEffectHandler::Trigger_Surface_Impacted(Player, Data);
				break;

			case ETundraPlayerOtterSwimmingState::Underwater:
				Data.BreachVelocity = MoveComp.Velocity;
				Data.BreachVerticalSpeed = MoveComp.WorldUp.DotProduct(MoveComp.Velocity);
				UPlayerSwimmingEffectHandler::Trigger_Surface_Breached(Player, Data);
				break;

			case ETundraPlayerOtterSwimmingState::Dive:
				break;

			default:
				break;
		}

		SwimmingComp.SurfaceData = SurfaceData;
		SwimmingComp.CurrentState = ETundraPlayerOtterSwimmingState::Surface;

		float VerticalSpeed = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
		AcceleratedSurfaceDistance.SnapTo(SwimmingComp.SurfaceData.DistanceToSurface, -VerticalSpeed);
		VerticalImpulseVelocity = FVector::ZeroVector;

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

		if(SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::Dive && SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::SurfaceDash)
			UPlayerSwimmingEffectHandler::Trigger_Surface_Stopped(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("SwimActiveState", SwimmingComp.InstigatedSwimmingActiveState.Get());
		TemporalLog.Value("CurrentState", SwimmingComp.CurrentState);
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
				
				const FVector Impulses = MoveComp.GetPendingImpulse();
				const FVector HorizontalImpulses = Impulses.ConstrainToPlane(MoveComp.WorldUp);
				const FVector VerticalImpulses = Impulses - HorizontalImpulses;
				VerticalImpulseVelocity += VerticalImpulses;
				//VerticalImpulseVelocity += MoveComp.Gravity * DeltaTime;
				if(VerticalImpulseVelocity.DotProduct(MoveComp.WorldUp) < 0.0)
					VerticalImpulseVelocity = FVector::ZeroVector;

				Movement.AddVelocity(VerticalImpulseVelocity);
				
				Movement.AddVelocity(HorizontalImpulses);

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