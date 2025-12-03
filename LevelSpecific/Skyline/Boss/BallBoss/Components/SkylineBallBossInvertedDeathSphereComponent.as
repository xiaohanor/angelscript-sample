
class USkylineBallBossInvertedDeathSphereComponent : USphereComponent
{
	default SphereRadius = 1500.0;
	UPROPERTY(EditAnywhere)
	bool bCanKillMio = false;
	UPROPERTY(EditAnywhere)
	bool bCanKillZoe = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnComponentEndOverlap.AddUFunction(this, n"OnExit");
	}

	UFUNCTION()
	void OnExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
    {
		if (!bCanKillMio && !bCanKillZoe)
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.IsMio() && bCanKillMio)
			Player.KillPlayer(FPlayerDeathDamageParams(FVector::ZeroVector, 1.0, bFallingDeath = true));
		if (Player.IsZoe() && bCanKillZoe)
			Player.KillPlayer(FPlayerDeathDamageParams(FVector::ZeroVector, 1.0, bFallingDeath = true));
    }
};