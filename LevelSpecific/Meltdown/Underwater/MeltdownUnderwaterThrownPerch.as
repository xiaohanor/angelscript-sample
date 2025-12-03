class AMeltdownUnderwaterThrownPerch : AGrapplePerchPoint
{
	UPROPERTY(EditAnywhere)
	FVector ThrowOffset = FVector(0, 0, 1000.0);
	UPROPERTY(EditAnywhere)
	float LerpSpeed = 2.0;
	UPROPERTY(EditAnywhere)
	float Lifetime = 30.0;

	FVector TargetLocation;
	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TargetLocation = ActorLocation;
		ActorLocation = TargetLocation + ThrowOffset;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		if (Timer >= Lifetime)
		{
			ActorLocation += FVector::DownVector * ((Timer - Lifetime) * 100.0 * DeltaSeconds);
			if (Timer >= Lifetime * 2.0)
				DestroyActor();
		}
		else
		{
			ActorLocation = Math::VInterpTo(
				ActorLocation, TargetLocation, 
				DeltaSeconds, LerpSpeed
			);
		}
	}
};