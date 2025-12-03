event void FGoldenAppleBowlEvent();

UCLASS(Abstract)
class AGoldenAppleBowl : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BowlRoot;

	UPROPERTY(DefaultComponent, Attach = BowlRoot)
	UPutdownInteractionComponent InteractionComp;

	UPROPERTY()
	FGoldenAppleBowlEvent OnApplePlaced;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnPickupPlacedInSocketEvent.AddUFunction(this, n"ApplePlaced");
	}

	UFUNCTION()
	private void ApplePlaced(UPickupComponent Pickup)
	{
		OnApplePlaced.Broadcast();
	}
}