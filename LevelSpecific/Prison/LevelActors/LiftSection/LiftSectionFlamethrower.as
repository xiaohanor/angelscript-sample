UCLASS(Abstract)
class ALiftSectionFlamethrower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFX;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshFlameActive;
	default SetActorHiddenInGame(true);


	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}

	bool bIsActive = false;
	UPROPERTY(EditAnywhere)
	float ActiveDuration = 2;
	float ActiveTimerTemp = 0;

	bool bForshadowActive = false;
	float ForshadowTimer = 0;
	float ForeshadowDuration = 1.2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForshadowTimer = ForeshadowDuration;
		ActiveTimerTemp = ActiveDuration;
		StaticMeshFlameActive.SetHiddenInGame(false);
		VFX.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bForshadowActive)
		{
			ForshadowTimer -= DeltaTime;
			if(ForshadowTimer <=0)
			{
				ActivateFlameThrower();
			}
		}



		if(bIsActive == false)
			return;

		ActiveTimerTemp -= DeltaTime;
		if(ActiveTimerTemp <= 0)
		{
			DeactivateFlamethrower();
		}
	}

	UFUNCTION() 
	void UnHideFlamethrower()
	{
		SetActorHiddenInGame(false);
	}
	UFUNCTION()
	void HideFlamethrower()
	{
		SetActorHiddenInGame(true);
	}


	UFUNCTION()
	void StartFlamethrower()
	{
		bForshadowActive = true;
		StaticMeshFlameActive.SetHiddenInGame(false);
		StaticMesh.SetHiddenInGame(true);
	}
	void ActivateFlameThrower()
	{
		bForshadowActive = false;
		ForshadowTimer = ForeshadowDuration;

		ActiveTimerTemp = ActiveDuration;
		bIsActive = true;
		VFX.Activate();
	}

	UFUNCTION(NotBlueprintCallable)
	private void DeactivateFlamethrower()
	{
		bIsActive = false;
		VFX.Deactivate();
		StaticMeshFlameActive.SetHiddenInGame(true);
		StaticMesh.SetHiddenInGame(false);
	}
}