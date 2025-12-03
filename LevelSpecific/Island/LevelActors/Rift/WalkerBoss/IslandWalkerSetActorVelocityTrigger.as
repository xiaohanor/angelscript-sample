class AIslandWalkerSetActorVelocityTrigger : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "BaseComp")
	UBoxComponent Trigger;

	UPROPERTY()
	bool bIsDisabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bIsDisabled)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		FVector ClampVelocity = Player.GetActorVelocity();
		ClampVelocity = ClampVelocity.GetClampedToSize(0, 1500);
		Player.SetActorVelocity(ClampVelocity);
	}

	UFUNCTION()
	void DisableVelocityTrigger()
	{
		bIsDisabled = true;
	}
	
}