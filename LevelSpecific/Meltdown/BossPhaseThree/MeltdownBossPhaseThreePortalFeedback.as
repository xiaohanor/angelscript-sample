class AMeltdownBossPhaseThreePortalFeedback : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerTrigger;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect PortalFF;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                         UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                         const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		Player.PlayForceFeedback(PortalFF,false,false,this);
	}
};