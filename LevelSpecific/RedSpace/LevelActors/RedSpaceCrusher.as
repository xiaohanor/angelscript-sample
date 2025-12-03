UCLASS(Abstract)
class ARedSpaceCrusher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftCrusherRoot;

	UPROPERTY(DefaultComponent, Attach = LeftCrusherRoot)
	USquishTriggerBoxComponent LeftSquishBox;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightCrusherRoot;

	UPROPERTY(DefaultComponent, Attach = RightCrusherRoot)
	USquishTriggerBoxComponent RightSquishBox;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CrushTimeLike;

	UPROPERTY(EditAnywhere)
	float StartDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float PauseDuration = 2.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	bool bCrushTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrushTimeLike.BindUpdate(this, n"UpdateCrush");
		CrushTimeLike.BindFinished(this, n"FinishCrush");

		if (StartDelay == 0.0)
			StartCrushing();
		else
			Timer::SetTimer(this, n"StartCrushing", StartDelay);
	}

	UFUNCTION()
	void StartCrushing()
	{
		CrushTimeLike.PlayFromStart();
		URedSpaceCrusherEventHandler::Trigger_StartMovingIn(this);
	}

	UFUNCTION()
	private void UpdateCrush(float CurValue)
	{
		float Offset = Math::Lerp(700.0, 0.0, CurValue);
		
		LeftCrusherRoot.SetRelativeLocation(FVector(0.0, -Offset, 0.0));
		RightCrusherRoot.SetRelativeLocation(FVector(0.0, Offset, 0.0));

		if (CurValue >= 0.9)
		{
			TriggerCrush();
		}
	}

	void TriggerCrush()
	{
		if (bCrushTriggered)
			return;

		bCrushTriggered = true;

		URedSpaceCrusherEventHandler::Trigger_Crush(this);

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ActorLocation, true, this, 1000.0, 400.0);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(CamShake, this, ActorLocation, 1000.0, 400.0);
	}

	UFUNCTION()
	private void FinishCrush()
	{
		bCrushTriggered = false;

		if (PauseDuration == 0.0)
			StartCrushing();
		else
			Timer::SetTimer(this, n"StartCrushing", PauseDuration);
	}
}

UCLASS(Abstract)
class URedSpaceCrusherEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMovingIn()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMovingOut()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Crush()
	{
	}

};