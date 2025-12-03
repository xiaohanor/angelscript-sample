class ATundraBossChargeKillCollision : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent Decal;
	default Decal.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;
	default SphereCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent VFXLocation;

	UPROPERTY()
	TSubclassOf<UDeathEffect> ChargeDeathEffect;

	float ActivationTimer = 0;
	float ActivationDuration = 0;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			if(PlayerCurrentlyInRestrictedZone(Player))
			{
				FPlayerDeathDamageParams DeathParams;
				DeathParams.ImpactDirection = -ActorRightVector;
				DeathParams.ForceScale = 10;
				Player.KillPlayer(DeathParams, ChargeDeathEffect);
			}
		}

		ActivationTimer += DeltaSeconds;
		if(ActivationTimer >= ActivationDuration)
		{
			SetActorTickEnabled(false);
		}
	}

	void ActivateChargeKillCollisionForDuration(float Duration)
	{
		ActivationDuration = Duration;
		SetActorTickEnabled(true);
		BP_ChargeKillCollisionActivated();
		Decal.SetHiddenInGame(true);
	}

	void ShowChargeDecal()
	{
		Decal.SetHiddenInGame(false);
	}

	bool PlayerCurrentlyInRestrictedZone(AHazePlayerCharacter Player)
	{
		if(GetHorizontalDistanceTo(Player) < SphereCollision.SphereRadius)
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ChargeKillCollisionActivated()
	{}
};