class ASkylineDownPipe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(EditAnywhere)
	APoleClimbActor Pole;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Timelike;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this,n"HandlePlayerEnter");
		Timelike.BindUpdate(this, n"HandleUpdate");
		Pole.OnStartPoleClimb.AddUFunction(this, n"HandleStartPoleClimb");
		Trigger.AddActorDisable(this);
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		Timelike.Play();
		Trigger.AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleUpdate(float CurrentValue)
	{
		Pivot.RelativeRotation = FRotator(0.0, 0.0, CurrentValue * 100.0);
	}

	UFUNCTION()
	private void HandleStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		if(bDoOnce)
		{
			Trigger.RemoveActorDisable(this);
		}
	}
};