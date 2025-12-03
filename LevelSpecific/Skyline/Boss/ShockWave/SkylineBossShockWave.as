class ASkylineBossShockWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ShockWaveScalePivot;

	UPROPERTY(EditDefaultsOnly)
	float InnerSafeRadius = 6000.0;

	UPROPERTY(EditDefaultsOnly)
	float Radius = 32000.0; // 10000.0

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.25;

	UPROPERTY(EditDefaultsOnly)
	float Speed = 6000.0; // 2000.0

	UPROPERTY(EditDefaultsOnly)
	float Height = 220.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve Curve;

	UPROPERTY(EditDefaultsOnly)
	float ImpulseOnBike = 1000;

	float Scale = 1.0;
	float HeightScale = 1.0;

	TPerPlayer<bool> bInsideRadiusLastFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Scale += Speed * 0.01 * DeltaSeconds;
		float ShockWaveRadius = Scale * 100.0;
		float Alpha = ShockWaveRadius / Radius;

		ShockWaveScalePivot.RelativeScale3D = FVector(Scale, Scale, (Height * 0.01) * Math::Max(SMALL_NUMBER, Math::Min(1.0, 1.0 + Curve.GetFloatValue(Alpha))));
		ShockWaveScalePivot.RelativeLocation = FVector::UpVector * 2500.0 * (Curve.GetFloatValue(Alpha));
 
		for (auto Player : Game::Players)
		{
			float Distance = Player.GetDistanceTo(this);

			if (IsContinuouslyGrounded(Player) && Distance > InnerSafeRadius)
			{
				if ((!bInsideRadiusLastFrame[Player] && Distance <= ShockWaveRadius) || (bInsideRadiusLastFrame[Player] && Distance > ShockWaveRadius))
				{
					auto Boss = TListedActors<ASkylineBoss>().Single;
					FPlayerDeathDamageParams Params;
					Params.ImpactDirection = (Player.ActorLocation - ActorLocation).SafeNormal;
					Player.DamagePlayerHealth(Damage, DamageEffect = Boss.DeathDamageComp.FireSoftDamageEffect, DeathEffect = Boss.DeathDamageComp.FireSoftDeathEffect, DeathParams = Params);

					AGravityBikeFree GravityBike = GravityBikeFree::GetGravityBike(Player);
					GravityBike.HoverComp.AddRotationalImpulse(Params.ImpactDirection * ImpulseOnBike);
				}
			}

			bInsideRadiusLastFrame[Player] = Distance <= ShockWaveRadius;
		}

		if (Scale * 100.0 > Radius)
			DestroyActor();
	}

	bool IsContinuouslyGrounded(AHazePlayerCharacter Player)
	{
		auto MoveComp = GravityBikeFree::GetGravityBike(Player).MoveComp;
		return MoveComp.PreviousHadGroundContact() && MoveComp.HasGroundContact();
	}
};