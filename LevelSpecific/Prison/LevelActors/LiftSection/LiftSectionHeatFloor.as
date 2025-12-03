UCLASS(Abstract)
class ALiftSectionHeatFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshForShadow;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshActive;
	default StaticMeshForShadow.SetHiddenInGame(true);
	default StaticMeshActive.SetHiddenInGame(true);


	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}

	bool bIsActive = false;
	float ActiveTimerTemp = 0;
	bool bForshadowActive = false;
	float ForshadowTimer = 0;
	float ForeshadowDuration = 1.65;
	bool bTurnOffManually = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForshadowTimer = ForeshadowDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bForshadowActive)
		{
			ForshadowTimer -= DeltaTime;
			if(ForshadowTimer <=0)
			{
				ActivateHeatFloor();
			}
		}



		if(bIsActive == false)
			return;

		ActiveTimerTemp -= DeltaTime;
		if(ActiveTimerTemp <= 0)
		{
			if(bTurnOffManually == false)
				DeactivateHeatFloor();
		}
	}

	UFUNCTION()
	void StartHeatFloor(float TelegrafDuration, float ActiveHeatDuration, bool ManuallyTurnOffHeat)
	{
		if(TelegrafDuration > 0)
		{
			ForshadowTimer = TelegrafDuration;
		}
		else
		{
			ForshadowTimer = ForeshadowDuration;
		}

		ActiveTimerTemp = ActiveHeatDuration;
		bTurnOffManually = ManuallyTurnOffHeat;
		
	
		
		bForshadowActive = true;
		StaticMeshForShadow.SetHiddenInGame(false);
		StaticMeshActive.SetHiddenInGame(true);
	}
	void ActivateHeatFloor()
	{
		bForshadowActive = false;
		ForshadowTimer = ForeshadowDuration;
		StaticMeshForShadow.SetHiddenInGame(true);
		StaticMeshActive.SetHiddenInGame(false);
		bIsActive = true;
	}

	UFUNCTION()
	private void DeactivateHeatFloor()
	{
		bIsActive = false;
		StaticMeshActive.SetHiddenInGame(true);
		StaticMeshForShadow.SetHiddenInGame(true);
	}
}