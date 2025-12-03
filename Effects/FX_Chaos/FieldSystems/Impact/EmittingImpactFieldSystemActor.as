
/**
 * Will spawn a sphere that simulates impacts every frame over a given time
 */

class AEmittingImpactFieldSystemActor : ABaseImpactFieldSystemActor
{
	default SphereCollision.SphereRadius = 8.0;

	default StrainMagnitude = 1000000.0;
	default ForceMagnitude = 20000.0;
	default TorqueMagnitude = 20000.0;

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

}