class ATundraRiverBoulder_DestructibleObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.GenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Boulder = Cast<ATundraRiverBoulder>(OtherActor);
		if(Boulder != nullptr)
		{
			Break();
		}
	}

	UFUNCTION()
	private void Break()
	{
		UTundraRiverBoulder_DestructibleObject_EffectHandler::Trigger_Break(this);
		SetActorHiddenInGame(true);
	}
};

namespace TundraRiverBoulderDestructibleObject
{
	UFUNCTION()
	TArray<ATundraRiverBoulder_DestructibleObject> GetAllTundraRiverBoulderDestructibleObjects()
	{
		return TListedActors<ATundraRiverBoulder_DestructibleObject>().Array;
	}
}