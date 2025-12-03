class USummitStoneBeastSlasherTentaclesCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(n"Tentacles");
	default TickGroup = EHazeTickGroup::AfterGameplay;

	USummitStoneBeastSlasherTentaclesComponent TentaclesComp;
	UBasicAICharacterMovementComponent MoveComp;
	USummitStoneBeastSlasherTentacleSettings Settings;
	USummitStoneBeastSlasherSettings SlasherSettings;
	UHazeActorRespawnableComponent RespawnComp;

	bool bRespawned = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TentaclesComp = USummitStoneBeastSlasherTentaclesComponent::GetOrCreate(Owner); 	
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);	
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		Settings = USummitStoneBeastSlasherTentacleSettings::GetSettings(Owner);
		SlasherSettings = USummitStoneBeastSlasherSettings::GetSettings(Owner);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bRespawned = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Settings.NumTentacles == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Settings.NumTentacles == 0)
			return true;
		if (bRespawned)
			return true; // Restart
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bRespawned = false;
		FTransform Transform = Owner.ActorTransform; 
		float Interval = 2.0 * PI / float(Settings.NumTentacles);
		for (int i = 0; i < Settings.NumTentacles; i++)
		{
			FSummitStoneBeastSlasherTentacle Tentacle;
			Tentacle.Effect = Niagara::SpawnLoopingNiagaraSystemAttached(TentaclesComp.TentacleFX, Owner.RootComponent);
			FVector Dir = FVector(0.0, Math::Cos(i * Interval), Math::Sin(i * Interval));
			Tentacle.LocalOrigin = Dir * Settings.TentacleOriginRadius * Math::RandRange(0.7, 1.3);
			FVector WorldOrigin = Transform.TransformPosition(Tentacle.LocalOrigin);
			Tentacle.AccNear.SnapTo(WorldOrigin);
			Tentacle.AccFar.SnapTo(WorldOrigin);
			Tentacle.AccEnd.SnapTo(WorldOrigin);
			Tentacle.UndulateOffset = Math::RandRange(0.0, 3.0);
			TentaclesComp.Tentacles.Add(Tentacle);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (FSummitStoneBeastSlasherTentacle Tentacle : TentaclesComp.Tentacles)
		{
			Tentacle.Effect.Deactivate();
		}
		TentaclesComp.Tentacles.Empty();
	}

	float GetUndulation(FSummitStoneBeastSlasherTentacle Tentacle, float Interval)
	{
		return Math::Sin((ActiveDuration + Tentacle.UndulateOffset) * Interval);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform Transform = TentaclesComp.WorldTransform;
		FVector Fwd = Transform.Rotation.ForwardVector;
		FVector Side = Transform.Rotation.RightVector;
		for (FSummitStoneBeastSlasherTentacle& Tentacle : TentaclesComp.Tentacles)
		{
			FVector Origin = Transform.TransformPosition(Tentacle.LocalOrigin);
			float Growth = (SlasherSettings.IntroGrowthDuration > 0.0) ? Math::Min(1.0, (ActiveDuration / SlasherSettings.IntroGrowthDuration)) : 1.0;
			if (!Tentacle.bBehaviourOverride)
			{
				// Default undulating behaviour
				FVector End = Origin + Fwd * (Settings.TentacleLength * Growth * (1.0 + GetUndulation(Tentacle, 2.11) * 0.05));
				FVector Delta = (End - Origin);
				Tentacle.AccNear.SpringTo(Origin + Fwd * 5.0 + Delta * Settings.NearFraction, Settings.NearStiffness, Settings.NearDamping, DeltaTime);
				Tentacle.AccFar.SpringTo(Origin + Delta * Settings.FarFraction + Side * GetUndulation(Tentacle, 1.47) * 150.0, Settings.FarStiffness, Settings.FarDamping, DeltaTime);
				Tentacle.AccEnd.SpringTo(End + Side * GetUndulation(Tentacle, 1.13) * 70.0, Settings.EndStiffness, Settings.EndDamping, DeltaTime);
			}

			Tentacle.Effect.SetVectorParameter(n"P0", Origin); 
			Tentacle.Effect.SetVectorParameter(n"P1", Tentacle.AccNear.Value); 
			Tentacle.Effect.SetVectorParameter(n"P2", Tentacle.AccFar.Value); 
			Tentacle.Effect.SetVectorParameter(n"P3", Tentacle.AccEnd.Value); 
		}

		for (FSummitStoneBeastSlasherTentacle& Tentacle : TentaclesComp.Tentacles)
		{
			Tentacle.bBehaviourOverride = false;
		}
	}
}
