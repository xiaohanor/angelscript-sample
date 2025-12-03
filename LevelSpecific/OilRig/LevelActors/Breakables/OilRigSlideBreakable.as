class AOilRigSlideBreakable : ABreakableActor
{
	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		BreakableComponent.BreakWithDefault();
	}
}