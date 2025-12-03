UCLASS(Abstract)
class ARedSpaceSpike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpikeRoot;

	UPROPERTY(DefaultComponent, Attach = SpikeRoot)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpikeTimeLike;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = false;

	UPROPERTY(EditAnywhere)
	float StartDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float PauseDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FVector2D KillRange = FVector2D(1.5, 2.1);

	private float LastSequenceTime;

	bool bDeathTriggerActive = false;

	bool bCycleStarted = false;
	bool bEffectTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathTriggerComp.DisableDeathTrigger(this);

		SetActorTickEnabled(false);

		if (bActiveFromStart)
			Activate();
	}

	UFUNCTION()
	void Activate()
	{
		StartSpiking();
	}

	UFUNCTION(NotBlueprintCallable)
	void StartSpiking()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void UpdateSpike(float CurValue)
	{
		float Offset = Math::Lerp(0.0, -400, CurValue);
		
		SpikeRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));

		float Rot = Math::Lerp(0.0, 360.0, CurValue);
		SpikeRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));

		if (!bEffectTriggered && CurValue >= 0.9)
			TriggerEffect();
	}

	void TriggerEffect()
	{
		bEffectTriggered = true;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, SpikeRoot.WorldLocation, true, this, 500.0);
		if (SceneView::IsFullScreen())
		{
			SceneView::FullScreenPlayer.PlayWorldCameraShake(CamShake, this, SpikeRoot.WorldLocation, 500.0, 200.0, Scale = 0.2, SamplePosition = EHazeWorldCameraShakeSamplePosition::NearestPlayer);
		}

		URedSpaceSpikeEffectEventHandler::Trigger_Impact(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float SequenceDuration = (SpikeTimeLike.Duration + PauseDuration);
		float SequenceTime = Math::Wrap(Time::PredictedGlobalCrumbTrailTime - StartDelay, 0, SequenceDuration);

		if (SequenceTime > KillRange.X && SequenceTime < KillRange.Y)
		{
			if (!bDeathTriggerActive)
			{
				bDeathTriggerActive = true;
				DeathTriggerComp.EnableDeathTrigger(this);
			}
		}
		else
		{
			if (bDeathTriggerActive)
			{
				bDeathTriggerActive = false;
				DeathTriggerComp.DisableDeathTrigger(this);
			}
		}

		if (SequenceTime < LastSequenceTime)
		{
			// We have looped back to the beginning, trigger the effect
			// Note that I've put the 'Pause' at the beginning of the sequence so we can trigger
			// the impact effect when it loops instead of needing more tracking.
			bCycleStarted = false;
			bEffectTriggered = false;
		}

		if (!bCycleStarted && SequenceTime >= PauseDuration)
		{
			bCycleStarted = true;
			URedSpaceSpikeEffectEventHandler::Trigger_StartMoving(this);
		}

		float AlphaValue = (SequenceTime - PauseDuration) / SpikeTimeLike.Duration;
		if (SpikeTimeLike.Curve.GetNumKeys() != 0)
			AlphaValue = SpikeTimeLike.Curve.GetFloatValue(AlphaValue);
		UpdateSpike(AlphaValue);

		LastSequenceTime = SequenceTime;
	}
}

class URedSpaceSpikeEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartMoving() {}
	UFUNCTION(BlueprintEvent)
	void Impact() {}
}