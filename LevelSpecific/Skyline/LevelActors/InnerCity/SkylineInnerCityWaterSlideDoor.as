class ASkylineInnerCityWaterSlideDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent CloseForceComp;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	TArray<AActor>Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		PlayerTrigger.OnActorBeginOverlap.AddUFunction(this, n"HandleEnter");
		PlayerTrigger.OnActorEndOverlap.AddUFunction(this, n"HandleLeave");
	}


	UFUNCTION()
	private void HandleEnter(AActor OverlappedActor, AActor OtherActor)
	{
		

		Players.Add(OtherActor);
		PrintToScreen("Enter:" + Players.Num(), 2.0);
		if(Players.Num() == 1)
		{
			
			CloseForceComp.AddDisabler(this);
					
			
		}	
		
	}

	UFUNCTION()
	private void HandleLeave(AActor OverlappedActor, AActor OtherActor)
	{
		Players.Remove(OtherActor);
		PrintToScreen("Enter:" + Players.Num(), 2.0);
		if(Players.Num() == 0)
		{
			CloseForceComp.RemoveDisabler(this);
			
		}
	}
};