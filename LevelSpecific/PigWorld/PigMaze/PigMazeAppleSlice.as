event void FPigMazeAppleSliceEvent();

UCLASS(Abstract)
class APigMazeAppleSlice : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SliceRootComp;

	UPROPERTY(DefaultComponent, Attach = SliceRootComp)
	UStaticMeshComponent AppleMeshComp;

	UPROPERTY(DefaultComponent, Attach = SliceRootComp)
	UCapsuleComponent PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	FPigMazeAppleSliceEvent OnCollected;

	bool bPickedUp = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SliceRootComp.SetRelativeRotation(FRotator(0.0, Math::RandRange(0.0, 360.0), 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PickUp();
	}

	UFUNCTION()
	void PickUp()
	{
		if (bPickedUp)
			return;

		bPickedUp = true;

		BP_PickedUp();

		AddActorDisable(this);

		OnCollected.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PickedUp() {}
}