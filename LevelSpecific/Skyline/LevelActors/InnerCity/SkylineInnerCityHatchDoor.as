class ASkylineInnerCityHatchDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	FHazeTimeLike Animation;

	float LockCounter;

	UPROPERTY(EditAnywhere)
	float MaxLocks;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		LockCounter = 0.0;
		Animation.BindUpdate(this, n"AnimationUpdate");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleOnActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleOnDeActivated");
	}

	UFUNCTION()
	private void HandleOnDeActivated(AActor Caller)
	{
		if(LockCounter>=0)
		{
			LockCounter--;
		}
		
	}

	UFUNCTION()
	private void HandleOnActivated(AActor Caller)
	{	
		LockCounter++;
		if(LockCounter>=MaxLocks)
		{
			Animation.Play();
			InterfaceComp.TriggerActivate();
		}
		
	}

	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		Pivot.RelativeLocation = FVector(-500.0 * CurrentValue, 1.0, 1.0);

		
	}

	UFUNCTION(DevFunction)
	void DevOpen()
	{
		Animation.Play();
		InterfaceComp.TriggerActivate();
	}

	UFUNCTION()
	void OpenHatch()
	{
		Animation.Play();
		InterfaceComp.TriggerActivate();
	}
};