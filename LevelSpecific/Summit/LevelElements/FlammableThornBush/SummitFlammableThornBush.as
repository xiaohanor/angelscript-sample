class ASummitFlammableThornBush : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitFireBreathResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ThornMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent CollisionCapsule;
	default CollisionCapsule.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CollisionCapsule.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
	default CollisionCapsule.CapsuleHalfHeight = 270;
	default CollisionCapsule.CapsuleRadius = 80;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent AcidCollisionCapsule;
	default AcidCollisionCapsule.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default AcidCollisionCapsule.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default AcidCollisionCapsule.CapsuleHalfHeight = 300;
	default AcidCollisionCapsule.CapsuleRadius = 200;

	UPROPERTY(DefaultComponent)
	UDeathVolumeComponent DeathVolumeComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ScaleDownDuration = 0.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DisappearScaleThreshold = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UNiagaraSystem OnFireSystem;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UNiagaraSystem DisappearSmoke;

	float TimeLastHitByFire = -MAX_flt;
	bool bHasBeenHitByFire = false;

	FVector StartScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"OnHit");
		StartScale = ActorScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHasBeenHitByFire)
		{
			float TimeSinceHitByFire = Time::GetGameTimeSince(TimeLastHitByFire);
			float ScaleDownAlpha = TimeSinceHitByFire / ScaleDownDuration;
			ScaleDownAlpha = Math::EaseIn(0.0, 1.0, ScaleDownAlpha, 4.0);

			float ScaleAlpha = (1 - ScaleDownAlpha);
			if(ScaleAlpha < DisappearScaleThreshold)
				DestroyTree();

			FVector NewScale = StartScale * ScaleAlpha;
			SetActorScale3D(NewScale);
		}
	}

	void DestroyTree()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DisappearSmoke, ActorLocation, ActorRotation);
		AddActorDisable(this);
	}

	UFUNCTION()
	private void OnHit(FSummitFireBreathHitParams Params)
	{
		if(bHasBeenHitByFire)
			return;
		bHasBeenHitByFire = true;
		TimeLastHitByFire = Time::GameTimeSeconds;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(OnFireSystem, ActorLocation, ActorRotation);

		// CollisionCapsule.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		DeathVolumeComp.DisableTrigger(this);
	}
};