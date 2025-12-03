class ASummitAcidBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrazierMeshComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent AcidHitCollision;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem AcidHitEffect;

	float LastTimeSpawnedParticle = MIN_flt;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(Time::GetGameTimeSince(LastTimeSpawnedParticle) < 0.1)
			return;

		if(Hit.HitComponent != AcidHitCollision)
			return;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(AcidHitEffect, Hit.ImpactLocation, FRotator::ZeroRotator);
		LastTimeSpawnedParticle = Time::GetGameTimeSeconds();
	}
};