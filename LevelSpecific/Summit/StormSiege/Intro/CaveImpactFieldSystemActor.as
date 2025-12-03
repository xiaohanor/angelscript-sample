class ACaveImpactFieldSystemActor : ABaseImpactFieldSystemActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	default SphereCollision.SphereRadius = 500.0;

	default StrainMagnitude = 900000.0;
	default ForceMagnitude = 600000.0;
	default TorqueMagnitude = 200000.0;

	UPROPERTY()
	float EndMagnitude;
	float MaxSize = 25000.0;

	float ExplansionAmount;
	float LifeTime = 2.0;
	float DestroyTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExplansionAmount = MaxSize / LifeTime;
		DestroyTime = Time::GameTimeSeconds + LifeTime;
		EndMagnitude = ForceMagnitude;
		ForceMagnitude = -ForceMagnitude;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SphereCollision.SphereRadius += ExplansionAmount * DeltaSeconds;

		ApplyFieldForceAtLocation(ActorLocation);

		if (Time::GameTimeSeconds > DestroyTime)
		{
			DestroyActor();
		}
	}
}