class ASkylineInnerCoffeeCup : AWhipSlingableObject
{
	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakVFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnWhipSlingableObjectImpact.AddUFunction(this, n"Break");
	}

	UFUNCTION()
	private void Break(TArray<FHitResult> HitResults, FVector Velocity)
	{
		if (BreakVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakVFX, ActorLocation);
		SetAutoDestroyWhenFinished(true);
	}
};