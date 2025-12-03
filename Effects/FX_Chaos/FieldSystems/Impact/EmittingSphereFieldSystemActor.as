
class AEmittingSphereFieldSystemActor : ABaseImpactFieldSystemActor
{
	default SphereCollision.SphereRadius = 8.0;

	default StrainMagnitude = 20000000.0;

	// default ForceMagnitude = 20000.0;
	// default TorqueMagnitude = 20000.0;

	default ForceMagnitude = 0.0;
	default TorqueMagnitude = 0.0;

	// will auto destroy the actor after the elapsed time
	UPROPERTY()
	float ActiveDuration = BIG_NUMBER;

	float ActiveTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyFieldForce();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Dt)
	{
		if(ActiveTime > 0)
			ApplyFieldForce();

		ActiveTime += Dt;

		if(ActiveTime > ActiveDuration)
		{
			//AddActorDisable(this);
			DestroyActor();
		}

		Debug::DrawDebugSphere(
			SphereCollision.GetWorldLocation(),
			SphereCollision.GetScaledSphereRadius(),
			LineColor = FLinearColor::Yellow,
			Duration = 0.0
		);
	}

	void ApplyFieldForce(FVector OptionalDirection = FVector::ZeroVector) override
	{
		ApplyDynamic();

		ApplyGlobalStrain();

		ApplyLinearForce(OptionalDirection);
		ApplyTorque();

		// ApplySleep();
		ApplyDisable();
	}
}