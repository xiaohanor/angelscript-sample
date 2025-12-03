UCLASS(Abstract)
class ADanceShowdown_ProgressTotemHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = BeatRotationRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BeatRotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	int StageNumber = 1;

	UPROPERTY(EditInstanceOnly)
	int MeasureNumber = 1;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> AdvanceCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ActivationEffect;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UNiagaraComponent ActivationEffect1Comp;
	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UNiagaraComponent ActivationEffect2Comp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotateAnimation;
	default RotateAnimation.Duration = 0.5;
	default RotateAnimation.Curve.AddDefaultKey(0, 0);
	default RotateAnimation.Curve.AddDefaultKey(0.5, 1);

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike BeatRotateAnimation;
	default BeatRotateAnimation.Duration = 0.15;
	default BeatRotateAnimation.Curve.AddDefaultKey(0, 0);
	default BeatRotateAnimation.Curve.AddDefaultKey(0.075, 1);
	default BeatRotateAnimation.Curve.AddDefaultKey(0.15, 0);

	UDanceShowdownScoreManager ScoreManager;
	UDanceShowdownRhythmManager RhythmManager;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScoreManager = DanceShowdown::GetManager().ScoreManager;
		RhythmManager = DanceShowdown::GetManager().RhythmManager;
		ScoreManager.OnScoreChanged.AddUFunction(this, n"ScoreChanged");
		RhythmManager.OnBeatEvent.AddUFunction(this, n"OnBeat");

		RotateAnimation.BindUpdate(this, n"TL_RotateUpdate");
		RotateAnimation.BindFinished(this, n"TL_RotateFinished");	
		BeatRotateAnimation.BindUpdate(this, n"TL_BeatRotateUpdate");

		if(ActivationEffect != nullptr)
		{
			ActivationEffect1Comp.Asset = ActivationEffect;
			ActivationEffect2Comp.Asset = ActivationEffect;
		}
	}

	UFUNCTION()
	private void TL_BeatRotateUpdate(float CurrentValue)
	{
		BeatRotationRoot.RelativeRotation = FRotator(0, 0, Math::Lerp(0, 15, CurrentValue));
	}

	UFUNCTION()
	private void OnBeat(FDanceShowdownOnBeatEventData Data)
	{
		// BeatRotateAnimation.PlayFromStart();
	}

	UFUNCTION()
	private void ScoreChanged(int Score)
	{
		if(DanceShowdown::GetManager().RhythmManager.GetCurrentStage() != StageNumber - 1)
			return;

		if(Score == MeasureNumber)
		{
			RotateAnimation.Play();
			FDanceShowdownTotemHeadEventData EventData;
			EventData.Mesh = MeshComp;
			UDanceShowdownTotemHeadEventHandler::Trigger_OnTotemHeadStartRotating(this, EventData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	private void TL_RotateFinished()
	{
		Game::GetMio().PlayCameraShake(AdvanceCameraShake, this);
		ActivationEffect1Comp.Activate();
		ActivationEffect2Comp.Activate();

		FDanceShowdownTotemHeadEventData EventData;
		EventData.Mesh = MeshComp;
		UDanceShowdownTotemHeadEventHandler::Trigger_OnTotemHeadStopRotating(this, EventData);
	}

	UFUNCTION()
	private void TL_RotateUpdate(float CurrentValue)
	{
		RotationRoot.RelativeRotation = FRotator(0, Math::Lerp(0, -180, CurrentValue), 0);
	}
};
