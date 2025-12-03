event void FIslandOverseerTowardsChaseComponentArrivedEvent();

class UIslandOverseerTowardsChaseComponent : UActorComponent
{
	AAIIslandOverseer Overseer;

	UPROPERTY()
	FIslandOverseerTowardsChaseComponentArrivedEvent OnArrived;

	float SplineDistance;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		OnArrived.AddUFunction(this, n"Arrived");
	}

	UFUNCTION()
	private void Arrived()
	{
		
	}
}