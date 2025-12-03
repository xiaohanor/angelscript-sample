UCLASS(Abstract)
class ASkylineBossTankMortarBallFire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly)
	float Radius = 1000.0;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.25;

	UPROPERTY(EditDefaultsOnly)
	float Duration = 200.0;

	UPROPERTY(EditDefaultsOnly)
	float RemoveTime = 5.0;

	TPerPlayer<bool> bInsideRadiusLastFrame;

	FHazeAcceleratedFloat AcceleratedFloat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo(1.0, 1.0, DeltaSeconds);

		ActorScale3D = FVector::OneVector * AcceleratedFloat.Value;

		for (auto Player : Game::Players)
		{
			// Only damage the player from the control side
			if(!Player.HasControl())
				continue;

			float Distance = Player.GetDistanceTo(this);

			if (IsContinuouslyGrounded(Player))
			{
				if ((!bInsideRadiusLastFrame[Player] && Distance <= Radius) || (bInsideRadiusLastFrame[Player] && Distance > Radius))
				{
					auto BossTank = TListedActors<ASkylineBossTank>().Single;
					FPlayerDeathDamageParams Params;
					Params.ImpactDirection = (Player.ActorLocation - ActorLocation).SafeNormal;
					Player.DamagePlayerHealth(Damage, Params, DamageEffect = BossTank.DeathDamageComp.FireImpactDamageEffect, DeathEffect = BossTank.DeathDamageComp.FireImpactDeathEffect);
				}
			}

			bInsideRadiusLastFrame[Player] = Distance <= Radius;
		}

/*
		if (GameTimeSinceCreation > Duration)
			DestroyActor();
*/
	}

	bool IsContinuouslyGrounded(AHazePlayerCharacter Player)
	{
		auto MoveComp = GravityBikeFree::GetGravityBike(Player).MoveComp;
		return MoveComp.PreviousHadGroundContact() && MoveComp.HasGroundContact();
	}

	void Remove()
	{
		Timer::SetTimer(this, n"RemoveInstant", RemoveTime);
		BP_SoonRemoved(RemoveTime);
	}

	UFUNCTION()
	void RemoveInstant()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SoonRemoved(float Time)
	{

	}
};