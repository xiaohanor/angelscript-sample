UCLASS(Abstract)
class ADanceShowdown_PoseIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLight;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ActivateEffect;

	UPROPERTY(EditInstanceOnly)
	int StageNumber = 1;

	UPROPERTY(EditInstanceOnly)
	EDanceShowdownPose Pose;

	ADanceShowdownManager DanceShowdownManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DanceShowdownManager = DanceShowdown::GetManager();
		DanceShowdownManager.PoseManager.OnNewPoseEvent.AddUFunction(this, n"OnNewPose");
		DanceShowdownManager.OnPlayerFail.AddUFunction(this, n"OnPlayerFail");
		DanceShowdownManager.PoseManager.OnPlayerFailedEvent.AddUFunction(this, n"OnPosePlayerFail");
		DanceShowdownManager.PoseManager.OnNewDisplayPoseEvent.AddUFunction(this, n"OnNewDisplayPose");
	}

	UFUNCTION()
	private void OnPosePlayerFail(UDanceShowdownPlayerComponent Player)
	{
		if(DanceShowdownManager.RhythmManager.GetCurrentStage() != StageNumber - 1)
			return;

		HideArrow();
	}

	UFUNCTION()
	private void OnPlayerFail()
	{
		if(DanceShowdownManager.RhythmManager.GetCurrentStage() != StageNumber - 1)
			return;

		HideArrow();
	}

	UFUNCTION()
	private void OnNewPose(EDanceShowdownPose NewPose)
	{
		PoseCheck(NewPose);
	}

	UFUNCTION()
	private void OnNewDisplayPose(EDanceShowdownPose NewPose)
	{
		PoseCheck(NewPose, false);
	}

	UFUNCTION()
	private void PoseCheck(EDanceShowdownPose NewPose, bool bShowEffect = true)
	{
		if(DanceShowdownManager.RhythmManager.GetCurrentStage() != StageNumber - 1)
			return;

		if(NewPose != Pose || DanceShowdownManager.PoseManager.bMeasureCanceled)
		{
			HideArrow();
			return;
		}

		if(bShowEffect)
		{
			ShowArrow();
		}
	}

	private void HideArrow()
	{
		SetActorHiddenInGame(true);

		// PointLight.SetHiddenInGame(true);
		// MeshComp.SetHiddenInGame(true);
	}

	private void ShowArrow()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ActivateEffect, ActorLocation);

		SetActorHiddenInGame(false);

		// PointLight.SetHiddenInGame(false);
		// MeshComp.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintCallable)
	void BP_ShowArrow()
	{
		ShowArrow();
	}

	UFUNCTION(BlueprintCallable)
	void BP_HideArrow()
	{
		HideArrow();
	}
};
