class ASkylineJetpackCombatZoneGround : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDecalComponent ExplodeIndicator;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent LaserEffect;

	UPROPERTY()
	TSubclassOf<AJetpackCombatZoneRocket> RocketClass;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerStumbleSheet);

	float StartTime;
	float TelegraphDuration = 3;
	bool bFired;
	float RocketTime;
	int RocketCount;
	int MaxRocketCount = 10;
	float RocketInterval = 0.1;
	FVector RocketStartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExplodeIndicator.SetVisibility(false, true);
		LaserEffect.SetVisibility(false);
	}

	UFUNCTION()
	void StartExplosion(FVector InRocketStartLocation)
	{
		if(StartTime > 0)
			return;

		RocketStartLocation = InRocketStartLocation;
		StartTime = Time::GetGameTimeSeconds();
		bFired = false;
		RocketCount = 0;

		LaserEffect.SetNiagaraVariableVec3("BeamStart", RocketStartLocation);
		LaserEffect.SetNiagaraVariableVec3("BeamEnd", ActorLocation);
		LaserEffect.SetNiagaraVariableFloat("BeamWidth", 50);
		LaserEffect.SetVisibility(true);

		ExplodeIndicator.SetRelativeScale3D(FVector(1,0,0));
		ExplodeIndicator.SetVisibility(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(StartTime > 0 && Time::GetGameTimeSince(StartTime) > TelegraphDuration && !bFired)
		{
			ExplodeIndicator.SetVisibility(false, true);
			LaserEffect.SetVisibility(false);

			if(RocketTime == 0 || Time::GetGameTimeSince(RocketTime) > RocketInterval)
			{
				float Degrees = (360.0 / 5) * RocketCount;
				FVector Direction = ActorForwardVector.RotateAngleAxis(Degrees, ActorUpVector);
				FVector Offset = Direction * (600.0/MaxRocketCount) * RocketCount;
				FVector Location = RocketStartLocation + Offset;
				auto Rocket = SpawnActor(RocketClass, Location);
				FVector Velocity = ((ActorLocation + Offset) - Location).GetSafeNormal() * 4000;
				Rocket.ProjectileComp.Launch(Velocity, Velocity.Rotation());
				Rocket.bSelfMoving = true;
				RocketCount++;
				RocketTime = Time::GetGameTimeSeconds();

				bFired = RocketCount > MaxRocketCount;
				if(bFired)
					StartTime = 0;
			}
		}

		float Scale = Math::Clamp(Time::GetGameTimeSince(StartTime) / (TelegraphDuration), 0, 1);
		LaserEffect.SetNiagaraVariableFloat("BeamWidth", (1-Scale) * 50);
		ExplodeIndicator.SetRelativeScale3D(FVector(1,Scale,Scale));
	}
}