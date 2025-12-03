event void FOnExplosionTriggered();

class AJetskiExplosionTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent CollisionComp;
	default CollisionComp.BoxExtent = FVector(2500, 500, 1500);
	
	UPROPERTY(EditDefaultsOnly, Category = "Explosion")
	UNiagaraSystem DefaultExplosionFX;

	UPROPERTY(EditDefaultsOnly, Category = "Explosion")
	TSubclassOf<USoundDefBase> DefaultSoundDef;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget), Category = "Explosion")
	FTransform ExplosionTransform;	

	UPROPERTY(EditInstanceOnly, Category = "Explosion")
	bool bUseCustomExplosion = false;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bUseCustomExplosion"), Category = "Explosion")
	UNiagaraSystem ExplosionFX;

	UPROPERTY(EditInstanceOnly, Category = "Explosion")
	bool bUseCustomSoundDef = false;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bUseCustomSoundDef"), Category = "Explosion")
	TSubclassOf<USoundDefBase> SoundDef;

	UPROPERTY(EditInstanceOnly, Category = "Explosion")
	bool bShouldOnlyTriggerOnce = true;

	bool bHasBeenTriggered = false;
	FVector TransformedExplosionLocation;
	FRotator TransformedExplosionRotation;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float InnerRadius = 8000.0;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float OuterRadius = 8000.0;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float Scale = 1.0;

	UPROPERTY()
	FOnExplosionTriggered OnExplosionTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		TransformedExplosionLocation = ActorTransform.TransformPosition(ExplosionTransform.Location);
		TransformedExplosionRotation = ActorTransform.TransformRotation(ExplosionTransform.Rotator());

		DefaultExplosionFX = bUseCustomExplosion ? ExplosionFX : DefaultExplosionFX;
		DefaultSoundDef = bUseCustomSoundDef ? SoundDef : DefaultSoundDef;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        if (bHasBeenTriggered && bShouldOnlyTriggerOnce)
			return;

		AJetski Jetski = Cast<AJetski>(OtherActor);
		if (Jetski == nullptr)
			return;

		bHasBeenTriggered = true;
		
		if(DefaultExplosionFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DefaultExplosionFX, TransformedExplosionLocation, TransformedExplosionRotation);

		OnExplosionTriggered.Broadcast();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(CameraShakeClass, this, TransformedExplosionLocation, InnerRadius, OuterRadius, 1.0, Scale);

    }
}