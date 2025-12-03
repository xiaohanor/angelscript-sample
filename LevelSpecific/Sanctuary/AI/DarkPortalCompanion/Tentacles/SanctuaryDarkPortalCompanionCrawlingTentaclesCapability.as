class USanctuaryDarkPortalCompanionCrawlingTentacleSettings : UHazeComposableSettings
{
	// Number of tentacles. Block and unblock companion tentacle capability to update this.
	UPROPERTY(Category = "Tentacles")
	int NumTentacles = 0;

	// Distance from actor origin to tentacle origin
	UPROPERTY(Category = "Tentacles")
	float TentacleOriginRadius = 1.0;

	UPROPERTY(Category = "Tentacles")
	float TentacleOuterRadius = 20.0;

	// How far tentacles can reach. When moving the TentacleReachAhead and TentacleStretchBehind settings will affect this.
	UPROPERTY(Category = "Tentacles")
	float TentacleReach = 300.0;

	// How slowly tentacle is moved to a new location when moved. This is sped up when moving fast.
	UPROPERTY(Category = "Tentacles")
	float TentacleReachDuration = 0.5;

	// How far ahead we predict location with velocity when placing tentacles, 0.0..0.5 recommended 
	UPROPERTY(Category = "Tentacles")
	float TentacleReachAhead = 0.1;	 

	// How much velocity matters when checking if a tentacle needs to be moved, -0.2..0.2 recommended
	UPROPERTY(Category = "Tentacles")
	float TentacleStretchBehind = -0.1;	

	// No tentacle can move to a new destination this many seconds after another moved. Tentacles that are stretched out too far will retract into the body instead.
	UPROPERTY(Category = "Tentacles")
	float TentacleMoveMinInterval = 0.02;

	// How often at least one tentacle needs to move
	UPROPERTY(Category = "Tentacles")
	float TentacleForceMoveInterval = 0.7;

	// How high we lift tentacle when moving it
	UPROPERTY(Category = "Tentacles")
	float TentacleStepLiftHeight = 10.0;
}


struct FSanctuaryDarkPortalCompanionCrawlingTentacle
{
	UNiagaraComponent Effect;
	FVector LocalOrigin;
	FVector TargetDestination;
	FHazeAcceleratedVector AccDestination;
	float ForceMoveTime;
	FHazeAcceleratedFloat StepAlpha;
	float ReachFactor;
	float HookFactor;
}

class USanctuaryDarkPortalCompanionCrawlingTentaclesCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(n"Tentacles");
	default TickGroup = EHazeTickGroup::AfterGameplay;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAIDestinationComponent DestComp;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryDarkPortalCompanionCrawlingTentacleSettings Settings;

	TArray<FSanctuaryDarkPortalCompanionCrawlingTentacle> Tentacles;
	int iTentacle;
	float AnyTentacleMoveTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 	
		DestComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);	
		Settings = USanctuaryDarkPortalCompanionCrawlingTentacleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CompanionComp.bReplaceWeaponPortal)
			return false;
		if (Settings.NumTentacles == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CompanionComp.bReplaceWeaponPortal)
			return true;
		if (CompanionComp.bTentacleReset)
			return true;
		if (Settings.NumTentacles == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.bTentacleReset = false;
		FTransform Transform = Owner.ActorTransform;
		float Interval = 1.0 * PI / float(Settings.NumTentacles);
		for (int i = 0; i < Settings.NumTentacles; i++)
		{
			FSanctuaryDarkPortalCompanionCrawlingTentacle Tentacle;
			Tentacle.Effect = Niagara::SpawnLoopingNiagaraSystemAttached(CompanionComp.CrawlyTentacle, Owner.RootComponent);
			FVector Dir = FQuat(FVector::UpVector, i * Interval * ((i % 2) == 0 ? 1.0 : -1.0)).ForwardVector;
				Tentacle.LocalOrigin = Dir * Settings.TentacleOriginRadius * Math::RandRange(0.7, 1.3);
			FVector Dest = Transform.TransformPosition(Dir * Settings.TentacleOriginRadius * 2.0);
			Dest.Z = CompanionComp.Player.ActorLocation.Z - Settings.TentacleOriginRadius;
			Tentacle.AccDestination.SnapTo(Transform.Location);
			Tentacle.TargetDestination = Dest;
			Tentacle.ForceMoveTime = Time::GameTimeSeconds + Settings.TentacleForceMoveInterval * Math::RandRange(1.0, 3.0);
			Tentacle.StepAlpha.SnapTo(1.0);
			Tentacle.ReachFactor = Math::RandRange(0.8, 1.1);
			Tentacle.HookFactor = Math::RandRange(10.0, 20.0);
			Tentacles.Add(Tentacle);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (FSanctuaryDarkPortalCompanionCrawlingTentacle Tentacle : Tentacles)
		{
			Tentacle.Effect.Deactivate();
		}
		Tentacles.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform Transform = Owner.ActorTransform;
		float Speed = Owner.ActorVelocity.Size();

		// Check if a tentacle needs to move
		iTentacle = (iTentacle + 1) % Tentacles.Num();
		if (DestComp.HasDestination())
		{
			float ReachFactor = Math::GetMappedRangeValueClamped(FVector2D(100.0, 500.0), FVector2D(0.1, 1.0), Speed);
			FSanctuaryDarkPortalCompanionCrawlingTentacle& Tentacle = Tentacles[iTentacle];
			if (ShouldMove(Tentacle, Transform, ReachFactor))
			{
				if (Time::GetGameTimeSince(AnyTentacleMoveTime) < Settings.TentacleMoveMinInterval)
					ReachFactor = 0.1;
				ReachFactor *= Tentacle.ReachFactor;
				FVector Offset = Transform.TransformVector(Tentacle.LocalOrigin) * (Settings.TentacleOuterRadius / Settings.TentacleOriginRadius) * ReachFactor;
				FVector Origin = Transform.Location + Offset;
				FVector ToDest = (DestComp.Destination - Transform.Location);
				FVector TentacleDest = Origin + ToDest.GetClampedToMaxSize(Settings.TentacleReach * ReachFactor);
				TentacleDest += Owner.ActorVelocity * Settings.TentacleReachAhead;
				TentacleDest += Offset * 1.5;
				TentacleDest += Math::GetRandomPointInSphere() * Settings.TentacleOuterRadius * ReachFactor;
				FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MoveComp);
				Trace.UseLine();
				Trace.IgnoreActor(Owner);
				Trace.IgnoreActor(CompanionComp.Player);
				FHitResult Hit = Trace.QueryTraceSingle(TentacleDest + FVector::UpVector * 40.0, TentacleDest - FVector::UpVector* 40.0);
				if (Hit.bBlockingHit)
					TentacleDest = Hit.Location;
				Tentacle.TargetDestination = TentacleDest;
				Tentacle.StepAlpha.SnapTo(Math::Clamp(1.0 - Tentacle.StepAlpha.Value, 0.0, 1.0));
				Tentacle.ForceMoveTime = Time::GameTimeSeconds + Settings.TentacleForceMoveInterval * Math::RandRange(3.0, 10.0);
				AnyTentacleMoveTime = Time::GameTimeSeconds;
			}
		}

		FVector2D ReachDurationFactorOutputRange = FVector2D(1.0, Math::Clamp(Settings.TentacleReachAhead, 0.1, 1.0));
		float ReachDurationFactor = Math::GetMappedRangeValueClamped(FVector2D(100.0, 500.0), ReachDurationFactorOutputRange, Speed);
		float ReachDuration = Settings.TentacleReachDuration * ReachDurationFactor;
		float StepHeightFactor = Math::GetMappedRangeValueClamped(FVector2D(100.0, 500.0), FVector2D(1.0, 3.0), Speed);
		for (FSanctuaryDarkPortalCompanionCrawlingTentacle& Tentacle : Tentacles)
		{
			// Update origin and reach quickly to destination
			FVector Origin = Transform.TransformPosition(Tentacle.LocalOrigin);
			FVector Dest = Tentacle.AccDestination.AccelerateTo(Tentacle.TargetDestination, ReachDuration, DeltaTime);
			float StepAlpha = Tentacle.StepAlpha.AccelerateTo(1.0, ReachDuration, DeltaTime);
			float StepHeight = Settings.TentacleStepLiftHeight * Math::Sin(StepAlpha * 2.0 * PI) * StepHeightFactor;
			FVector StepUp = Owner.ActorUpVector;

			Tentacle.Effect.SetVectorParameter(n"P0", Origin); 
			Tentacle.Effect.SetVectorParameter(n"P1", Origin + (Origin - Transform.Location).GetSafeNormal2D() * Settings.TentacleOriginRadius * 2.0 + StepUp * Settings.TentacleOriginRadius * -2.1); 
			Tentacle.Effect.SetVectorParameter(n"P2", Dest + StepUp * Settings.TentacleOriginRadius * 1.0 + StepUp * StepHeight + (Origin - Transform.Location).GetSafeNormal() * Tentacle.HookFactor * 10); 
			Tentacle.Effect.SetVectorParameter(n"P3", Dest + StepUp * StepHeight); 
		}
	}

	bool ShouldMove(FSanctuaryDarkPortalCompanionCrawlingTentacle Tentacle, FTransform Transform, float ReachFactor)
	{
		if (Tentacle.StepAlpha.Value < 0.99)
			return false; // Can't start a ne step mid-step
		if (Time::GameTimeSeconds > Tentacle.ForceMoveTime)
			return true;
		if (Time::GameTimeSeconds > AnyTentacleMoveTime + Settings.TentacleForceMoveInterval)
			return true;
		FVector StretchLocation = Tentacle.AccDestination.Value + Owner.ActorVelocity * Settings.TentacleStretchBehind;
		if (!Transform.TransformPosition(Tentacle.LocalOrigin).IsWithinDist(StretchLocation, Settings.TentacleReach * 1.1 * ReachFactor))
			return true;
		return false;
	}
}
