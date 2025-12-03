class AIslandOverseerDoorShakeSpike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USceneComponent Spike;

	UPROPERTY(DefaultComponent, Attach=Spike)
	UBoxComponent DamageCollision;

	UPROPERTY(DefaultComponent)
	USceneComponent Indicator;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditInstanceOnly)
	int Index;

	bool bActive;
	bool bIndicated;
	FVector OriginalLocation;
	FVector AttackLocation;
	FVector TelegraphLocation;
	FHazeAcceleratedVector AccLocation;
	TArray<AHazePlayerCharacter> HitPlayers;

	float AttackDuration = 0.5;
	float ReturnDuration = 1.25;
	float AttackDistance = 900;
	float TelegraphDistance = 75;
	float IndicationDelay;
	float IndicationDelayPerSpike = 0.25;
	float AttackDelay = 1;
	float ActivationTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalLocation = Spike.WorldLocation;
		Indicator.SetVisibility(false, true);
	}

	void Initialize(AHazeActor Owner, float InIndicationDelay)
	{
		AttackLocation = ActorLocation + -ActorForwardVector * AttackDistance;
		TelegraphLocation = ActorLocation + -ActorForwardVector * TelegraphDistance;
		IndicationDelay = InIndicationDelay;
		AccLocation.SnapTo(ActorLocation);
	}

	void Indicate()
	{
		Indicator.SetVisibility(true, true);
	}

	void Deindicate()
	{
		Indicator.SetVisibility(false, true);
	}

	void Activate()
	{
		bIndicated = false;
		bActive = true;
		ActivationTime = Time::GetGameTimeSeconds();
		HitPlayers.Empty();
	}

	void Deactivate()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActive)
			return;

		if(Time::GetGameTimeSince(ActivationTime) < IndicationDelay)
			return;

		if(!bIndicated)
		{
			Indicate();
			bIndicated = true;
		}

		if(Time::GetGameTimeSince(ActivationTime) < IndicationDelay + AttackDelay)
		{
			AccLocation.AccelerateTo(TelegraphLocation, AttackDelay / 2, DeltaSeconds);
			Spike.WorldLocation = AccLocation.Value;
			return;
		}

		if(bActive && Time::GetGameTimeSince(ActivationTime) < IndicationDelay + AttackDelay + AttackDuration)
		{
			AccLocation.AccelerateTo(AttackLocation, AttackDuration, DeltaSeconds);

			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(HitPlayers.Contains(Player))
					return;
				if(Overlap::QueryShapeOverlap(DamageCollision.GetCollisionShape(), DamageCollision.WorldTransform, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
				{
					HitPlayers.Add(Player);
					Player.DamagePlayerHealth(0.6, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);

					FStumble Stumble;
					FVector Dir = (Player.ActorLocation - ActorLocation).GetNormalizedWithFallback(-Player.ActorForwardVector);
					Stumble.Move = Dir * 350;
					Stumble.Duration = 0.25;
					Player.ApplyStumble(Stumble);
				}
			}
		}
		else
		{
			Deindicate();
			AccLocation.AccelerateTo(OriginalLocation, ReturnDuration, DeltaSeconds);
		}
		
		Spike.WorldLocation = AccLocation.Value;

		if(Time::GetGameTimeSince(ActivationTime) > IndicationDelay + AttackDelay + AttackDuration + ReturnDuration)
			Deactivate();
	}
}