class AMeltdownBossPhaseThreeFallingObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DeathExplosion;

	int Health = 3.0;

	float PitchRot;
	float YawRot;
	float RollRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		PitchRot = Math::RandRange(100.0, 300.0);
		YawRot = Math::RandRange(100.0, 300.0);
		RollRot = Math::RandRange(100.0, 300.0);

		ResponseComp.OnGlitchHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(FMeltdownGlitchImpact Impact)
	{
		Health -= 1;
		Print("Hit", 5.0);
	}

	// UFUNCTION()
	// private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                        UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	//                        const FHitResult&in SweepResult)
	// {
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

	// 	if(Player != nullptr)
	// 	Player.DamagePlayerHealth(0.5);
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(PitchRot,YawRot,RollRot) * DeltaSeconds);
	//	AddActorWorldOffset(FVector::UpVector * 1400.0 * DeltaSeconds);

		if(Health <= 0.0)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathExplosion, ActorLocation);
			AddActorDisable(this);
		}
	}
};