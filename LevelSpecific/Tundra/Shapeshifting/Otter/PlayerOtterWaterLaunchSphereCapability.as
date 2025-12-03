class UTundraPlayerOtterWaterLaunchSphereCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroupOrder = 6;

	UTundraPlayerOtterComponent OtterComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftComponent;
	UTundraPlayerOtterWaterLaunchSphereContainer LaunchSphereContainer;
	UPlayerMovementComponent MoveComp;
	UPlayerSwimmingComponent SwimmingComp;
	USweepingMovementData Movement;

	ATundraPlayerOtterWaterLaunchSphere CurrentLaunchSphere;
	float CurrentDistance;
	float CurrentSpeed;
	float TimeOfReachEnd = -100.0;
	FVector CenterDirection;
	bool bReachedEnd = false;
	bool bTriggeredOnLaunch = false;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && CurrentLaunchSphere != nullptr)
		{
			if(Player.ActorCenterLocation.Distance(CurrentLaunchSphere.SphereComponent.WorldLocation) > CurrentLaunchSphere.SphereComponent.ScaledSphereRadius)
				CurrentLaunchSphere = nullptr;
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
		ShapeshiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		LaunchSphereContainer = UTundraPlayerOtterWaterLaunchSphereContainer::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerOtterWaterLaunchSphereActivatedParams& Params) const
	{
		if(ShapeshiftComponent.CurrentShapeType != ETundraShapeshiftShape::Small)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;
		
		if(SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return false;

		for(auto LaunchSphere : LaunchSphereContainer.LaunchSpheres)
		{
			if(LaunchSphere == CurrentLaunchSphere)
				return false;

			if(Player.ActorCenterLocation.Distance(LaunchSphere.SphereComponent.WorldLocation) < LaunchSphere.SphereComponent.ScaledSphereRadius)
			{
				Params.LaunchSphere = LaunchSphere;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ShapeshiftComponent.CurrentShapeType != ETundraShapeshiftShape::Small)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasCeilingContact())
			return true;

		if(SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerOtterWaterLaunchSphereActivatedParams Params)
	{
		CurrentLaunchSphere = Params.LaunchSphere;
		CurrentDistance = CurrentLaunchSphere.SphereComponent.WorldLocation.Distance(Player.ActorCenterLocation);
		CurrentSpeed = CurrentLaunchSphere.StartMagneticSpeed;

		FTundraPlayerOtterOnEnterLaunchSphereEffectParams EffectParams;
		EffectParams.CurrentLaunchSphere = CurrentLaunchSphere;
		// Figure out how long it will take to reach center of sphere, use quadratic formula to solve for t in following equation: 0.5at^2 + ut − s = 0 (u = initialVel, t = time, a = acceleration, s = displacement) -> t = (-u + sqrt(u^2 - 2as)) / a
		EffectParams.DurationUntilLaunch = (CurrentSpeed + Math::Sqrt(Math::Square(CurrentSpeed) - 2 * CurrentLaunchSphere.MagneticAcceleration * CurrentDistance)) / CurrentLaunchSphere.MagneticAcceleration;
		// Add launch delay to duration
		EffectParams.DurationUntilLaunch = CurrentLaunchSphere.LaunchDelay;
		UTundraPlayerOtterEffectHandler::Trigger_OnEnterLaunchSphere(OtterComp.OtterActor, EffectParams);

		bReachedEnd = false;
		CenterDirection = (CurrentLaunchSphere.SphereComponent.WorldLocation - Player.ActorCenterLocation).GetSafeNormal();
		TimeOfReachEnd = -100.0;
		bTriggeredOnLaunch = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Time = Time::GetGameTimeSeconds();

				if(!bReachedEnd)
				{
					CurrentSpeed += CurrentLaunchSphere.MagneticAcceleration * DeltaTime;
					float CurrentDelta = CurrentSpeed * DeltaTime;
					if(CurrentDelta > CurrentDistance)
					{
						CurrentDelta = CurrentDistance;
						bReachedEnd = true;
						TimeOfReachEnd = Time;
						CurrentDistance = 0.0;
					}
					else
						CurrentDistance -= CurrentDelta;

					PrintToScreen(f"{CurrentDistance}");

					Movement.AddDeltaWithCustomVelocity(CenterDirection * CurrentDelta, FVector::ZeroVector);
					Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, (MoveComp.Velocity + (CenterDirection * CurrentSpeed)).GetSafeNormal().ToOrientationRotator(), DeltaTime, 200.0));
				}

				if(bReachedEnd && Time - TimeOfReachEnd > CurrentLaunchSphere.LaunchDelay)
				{
					if(!bTriggeredOnLaunch)
					{
						bTriggeredOnLaunch = true;
						
						FTundraPlayerOtterOnLaunchSphereLaunchEffectParams Params;
						Params.CurrentLaunchSphere = CurrentLaunchSphere;
						Params.DurationToSurface = 500.0 / CurrentLaunchSphere.LocalImpulseToApply.Z;
						UTundraPlayerOtterEffectHandler::Trigger_OnLaunchSphereLaunch(OtterComp.OtterActor, Params);
						CurrentLaunchSphere.Launch();
					}

					Movement.AddVelocity(CurrentLaunchSphere.SphereComponent.WorldTransform.TransformVectorNoScale(CurrentLaunchSphere.LocalImpulseToApply));
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"UnderwaterSwimming");
		}
	}
}

struct FTundraPlayerOtterWaterLaunchSphereActivatedParams
{
	ATundraPlayerOtterWaterLaunchSphere LaunchSphere;
}