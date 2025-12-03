class AClimbSandFishDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent TriggerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"OnSandFishOverlap");
	}

	UFUNCTION(BlueprintEvent)
	private void OnSandFishOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
	}
}