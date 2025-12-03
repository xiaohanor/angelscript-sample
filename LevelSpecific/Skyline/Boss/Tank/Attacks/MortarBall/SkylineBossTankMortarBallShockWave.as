UCLASS(Abstract)
class ASkylineBossTankMortarBallShockWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ShockWaveScalePivot;

	UPROPERTY(EditDefaultsOnly)
	float Radius = 7000.0; // 10000.0

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.25;

	UPROPERTY(EditDefaultsOnly)
	float Speed = 5000.0; // 2000.0

	UPROPERTY(EditDefaultsOnly)
	float Height = 80.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve Curve;

	UPROPERTY(EditDefaultsOnly)
	float ImpulseOnBike = 1000;

	float Scale = 1.0;
	float HeightScale = 1.0;

	TPerPlayer<bool> bInsideRadiusLastFrame;

	AHazePlayerCharacter UniqueForPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (UniqueForPlayer != nullptr)
		{
			TArray<UPrimitiveComponent> Primitives;
			GetComponentsByClass(Primitives);
			for (auto Primitive : Primitives)
				Primitive.SetRenderedForPlayer(UniqueForPlayer.OtherPlayer, false);

			TArray<UNiagaraComponent> NiagaraComps;
			GetComponentsByClass(NiagaraComps);
			for (auto NiagaraComp : NiagaraComps)
				NiagaraComp.SetRenderedForPlayer(UniqueForPlayer.OtherPlayer, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Scale += Speed * 0.01 * DeltaSeconds;
		float ShockWaveRadius = Scale * 100.0;
		float Alpha = ShockWaveRadius / Radius;

		ShockWaveScalePivot.RelativeScale3D = FVector(Scale, Scale, (Height * 0.01));
		ShockWaveScalePivot.RelativeLocation = FVector::UpVector * -600 * (1.0 - Curve.GetFloatValue(Alpha));

		for (auto Player : Game::Players)
		{
			if (UniqueForPlayer != nullptr && UniqueForPlayer != Player)
				continue;

			// Only damage the player from the control side
			if(!Player.HasControl())
				continue;

			float Distance = Player.GetDistanceTo(this);

			if (IsContinuouslyGrounded(Player))
			{
				if ((!bInsideRadiusLastFrame[Player] && Distance <= ShockWaveRadius) || (bInsideRadiusLastFrame[Player] && Distance > ShockWaveRadius))
				{
					if (Player.ActorLocation.Z < ActorLocation.Z + Height)
					{
						auto BossTank = TListedActors<ASkylineBossTank>().Single;
						FPlayerDeathDamageParams Params;
						Params.ImpactDirection = (Player.ActorLocation - ActorLocation).SafeNormal;
						Player.DamagePlayerHealth(Damage, DamageEffect = BossTank.DeathDamageComp.FireImpactDamageEffect, DeathEffect = BossTank.DeathDamageComp.FireImpactDeathEffect, DeathParams = Params);

						AGravityBikeFree GravityBike = GravityBikeFree::GetGravityBike(Player);
						GravityBike.HoverComp.AddRotationalImpulse(Params.ImpactDirection * ImpulseOnBike);
					}
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