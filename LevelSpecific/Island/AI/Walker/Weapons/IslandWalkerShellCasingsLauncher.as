class UIslandWalkerShellCasingsLauncher : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UIslandWalkerSettings Settings;

	TArray<FVector> Locations;
	TArray<FVector> Velocities;
	TArray<float> LifeTimes;
	TArray<float32> AgeFractions;
	TArray<bool> bHasReachedFloor;
	int CurrentIndex = 0;

	float ArenaHeight;

	TPerPlayer<float> LastPlayerDamageTime;

	const float Gravity = 1600.0;
	const float CoefficientOfRestitution = 0.4; // What fraction of speed remains after bounce.
	const float AirFrictionFactor = Math::Exp(-0.2);
	const float GroundFrictionFactor = Math::Exp(-2.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(Owner));		
	}
	
	void ReserveShellCasings(int MaxNumber)
	{
		int PrevNum = LifeTimes.Num();
		if (MaxNumber <= PrevNum)
			return;
		Locations.SetNumZeroed(MaxNumber);
		Velocities.SetNumZeroed(MaxNumber);
		LifeTimes.SetNumZeroed(MaxNumber);
		AgeFractions.SetNumZeroed(MaxNumber);
		bHasReachedFloor.SetNumZeroed(MaxNumber);
	}

	void Launch(FVector InheritedWorldVelocity)
	{
		SetComponentTickEnabled(true);
		CurrentIndex = GetAvailableShellIndex(CurrentIndex);
		if (!ensure(LifeTimes.IsValidIndex(CurrentIndex), "You need to reserve enough shell casings before trying to launch."))
		{
			CurrentIndex = LifeTimes.Num();
			ReserveShellCasings(CurrentIndex + 1);
		}

		FRotator LaunchBaseRot = WorldRotation;
		LaunchBaseRot.Yaw += Math::RandRange(-1.0, 1.0) * Settings.GatlingCasingsEjectScatterYaw;
		LaunchBaseRot.Pitch += Math::RandRange(-1.0, 1.0) * Settings.GatlingCasingsEjectScatterPitch;
		FVector LaunchVel = LaunchBaseRot.RotateVector(Settings.GatlingCasingsEjectSpeed);
		LaunchVel += InheritedWorldVelocity.GetClampedToMaxSize(500.0);

		Locations[CurrentIndex] = WorldLocation;
		Velocities[CurrentIndex] = LaunchVel;
		LifeTimes[CurrentIndex] = Math::RandRange(0.8, 1.0) * Settings.GatlingCasingsLifeTime;
		AgeFractions[CurrentIndex] = 0.0;
		bHasReachedFloor[CurrentIndex] = false;
		CurrentIndex++;
	}

	private int GetAvailableShellIndex(int Index)
	{
		for (int i = 0; i < LifeTimes.Num(); i++)
		{
			if (LifeTimes[(Index + i) % LifeTimes.Num()] == 0)
				return (Index + i) % LifeTimes.Num();
		}	
		return -1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = LifeTimes.Num() - 1; i >= 0; i--)
		{
			if (LifeTimes[i] == 0.0)
				continue;

			AgeFractions[i] += float32(DeltaTime / LifeTimes[i]);
			if (AgeFractions[i] > 1.0)
			{
				LifeTimes[i] = 0.0;
				AgeFractions[i] = 1.0;
				CurrentIndex = i;
				continue;
			}

			// Fall 
			Velocities[i].Z -= Gravity * DeltaTime;
			if (Locations[i].Z < ArenaHeight + 5.0)
				Velocities[i] *= Math::Pow(GroundFrictionFactor, DeltaTime); // In bounce or rolling along floor
			else		
				Velocities[i] *= Math::Pow(AirFrictionFactor, DeltaTime); // Falling/rising
			Locations[i] += Velocities[i] * DeltaTime;
			Locations[i].Z -= Gravity * Math::Square(DeltaTime) * 0.5;

			if (Locations[i].Z < ArenaHeight)
			{
				// Bounce (no need to use reflection since floor is flat)
				Velocities[i].Z *= -CoefficientOfRestitution; 

				// Redirected delta will be as high above arena as we would have penetrated, modified by energy lost in bounce
				Locations[i].Z = ArenaHeight + (ArenaHeight - Locations[i].Z) * CoefficientOfRestitution; 

				if(bHasReachedFloor[i] == false)
				{
					FIslandWalkerShellExplosionEventData ShellData;
					ShellData.Location = Locations[i];
					ShellData.Velocity = Velocities[i];
					UIslandWalkerEffectHandler::Trigger_OnShellExplosion(Cast<AHazeActor>(Owner), ShellData);
				}

				bHasReachedFloor[i] = true;
			}
		}

		// Check for player damage
		const float DamageRadius = Settings.GatlingCasingsDamageRadius;
		const float FFRadius = DamageRadius + 1500;
		for (AHazePlayerCharacter Target : Game::Players)
		{
			if (!Target.HasControl())
				continue;

			if (Time::GetGameTimeSince(LastPlayerDamageTime[Target]) < Settings.GatlingCasingsDamageInterval)
				continue;

			FVector TargetLoc = Target.ActorCenterLocation;
			for (int i = 0; i < AgeFractions.Num(); i++)
			{
				if ((AgeFractions[i] > 0.1) &&
					(AgeFractions[i] < 0.990) &&
					Locations[i].IsWithinDist(TargetLoc, FFRadius))
				{
					Target.PlayForceFeedback(ForceFeedback::Default_Light, this, 1 - (Locations[i].Distance(TargetLoc) / FFRadius));
				}

				if ((AgeFractions[i] < 0.1) ||
					(AgeFractions[i] > 0.990) ||
					!Locations[i].IsWithinDist(TargetLoc, DamageRadius))
					continue;

				CrumbDamagePlayer(Target, Locations[i]);
				break;
			}
		}

		if (LifeTimes.Num() == 0)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDamagePlayer(AHazePlayerCharacter Target, FVector DamageLoc)
	{
		LastPlayerDamageTime[Target] = Time::GameTimeSeconds;
		Target.DealTypedDamageBatchedOverTime(Owner, Settings.GatlingCasingsDamagePerSecond * Settings.GatlingCasingsDamageInterval, EDamageEffectType::Poison, EDeathEffectType::Poison);
		Target.ApplyAdditiveHitReaction(Target.ActorCenterLocation - DamageLoc, EPlayerAdditiveHitReactionType::Small);
		FVector StumbleMove = (Target.ActorLocation - DamageLoc).GetNormalized2DWithFallback(-Target.ActorForwardVector) * 400.0;
		Target.ApplyStumble(StumbleMove, 0.6);
		UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(Target);
	}

}



