event void FIslandOverseerSideChaseComponentArrivedEvent();

class UIslandOverseerSideChaseComponent : UActorComponent
{
	AAIIslandOverseer Overseer;

	UPROPERTY()
	FIslandOverseerSideChaseComponentArrivedEvent OnArrived;

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