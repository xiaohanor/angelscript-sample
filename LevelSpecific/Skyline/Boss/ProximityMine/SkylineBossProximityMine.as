class ASkylineBossProximityMine : ASkylineBossProjectile
{
	UPROPERTY(EditDefaultsOnly)
	float ExplodeTimer = 6.0;

	float ExplodeTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		ExplodeTime = Time::GameTimeSeconds + ExplodeTimer;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if (Time::GameTimeSeconds > ExplodeTime)
			Explode();
	}

	UFUNCTION()
	void Explode()
	{
		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{

	}
}