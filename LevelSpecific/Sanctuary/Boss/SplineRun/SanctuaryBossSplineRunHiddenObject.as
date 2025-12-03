class ASanctuaryBossSplineRunHiddenObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AKineticMovingActor MovingActor;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossSplineRunPushEssence PushEssence;


	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PushEssence.OnBothCompletedMash.AddUFunction(this, n"HandleButtonMashCompleted");
		
	}



	UFUNCTION()
	private void HandleButtonMashCompleted()
	{
		if(bDoOnce)
		{
			bDoOnce = false;
			MovingActor.ActivateForward();
		}
		
	}
};