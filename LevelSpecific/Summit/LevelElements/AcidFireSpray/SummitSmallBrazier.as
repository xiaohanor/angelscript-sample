class ASummitSmallBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent FireComp;
	default FireComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UAcidSprayContraptionResponseComponent ResponseComp;

	float ActiveTime;

	UPROPERTY(EditAnywhere)
	float ActiveDuration = 9.5;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnAcidSprayIgnite.AddUFunction(this, n"OnAcidSprayIgnite");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < ActiveTime)
		{
			if (!bIsActive)
			{
				bIsActive = true;
				FireComp.Activate();
			}
		}
		else
		{
			if (bIsActive)
			{
				bIsActive = false;
				FireComp.Deactivate();
			}			
		}
	}

	UFUNCTION()
	private void OnAcidSprayIgnite()
	{
		ActiveTime = Time::GameTimeSeconds + ActiveDuration;
	}
}