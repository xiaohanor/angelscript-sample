class ASummitTopDownLaserCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BeamMeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	USceneComponent TargetComp;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitRollingActivator Activator;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitTopDownLaserCannonDestroyableWall DestroyableWall;

	UPROPERTY()
	UNiagaraSystem TargetEffect;

	UPROPERTY()
	UNiagaraSystem BeamEffect;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BeamShowDuration = 0.5;

	float TimeLastActivated;
	bool bBeamIsShowing = false; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Activator != nullptr)
			Activator.OnActivated.AddUFunction(this, n"OnActivated");
		BeamMeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bBeamIsShowing)
			return;

		if(Time::GetGameTimeSince(TimeLastActivated) < BeamShowDuration)
			return;

		// BeamMeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);
		bBeamIsShowing = false;
	}

	UFUNCTION()
	private void OnActivated(FSummitRollingActivatorActivationParams Params)
	{
		// BeamMeshComp.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
		TimeLastActivated = Time::GameTimeSeconds;
		bBeamIsShowing = true;
		BP_OnActivated();

		USummitTopDownLaserCannonEventHandler::Trigger_OnLaserActivated(this);

		if(DestroyableWall != nullptr)
			DestroyableWall.GetDestroyed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated()
	{

	}

};