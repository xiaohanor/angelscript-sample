UCLASS(Abstract)
class AMagneticFieldCrusher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USquishTriggerBoxComponent SquishBox;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = true;

	UPROPERTY(EditAnywhere)
	float CrushDelay = 2.5;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShakeClass;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;

	FTimerHandle CrushTimerHandle;

	bool bCrushing = false;
	bool bActive = false;
	bool bConstraintHit = false;

	float PredictedTimeAtStart = 0.0;
	float BurstedTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		if (bActiveFromStart && HasControl())
			NetActivateAtTime(Time::GetActorControlCrumbTrailTime(this));

		TranslateComp.OnConstraintHit.AddUFunction(this, n"ConstraintHit");

		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"Bursted");
	}

	UFUNCTION(NetFunction)
	private void NetActivateAtTime(float StartTime)
	{
		PredictedTimeAtStart = StartTime;
		bActive = true;
	}

	UFUNCTION()
	private void Bursted(FMagneticFieldData Data)
	{
		BurstedTime = Time::GetActorControlCrumbTrailTime(this);
	}

	UFUNCTION()
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
		{
			UMagneticFieldCrusherEffectEventHandler::Trigger_FullyRetracted(this);
			return;
		}

		if (Edge != EFauxPhysicsTranslateConstraintEdge::AxisX_Max)
			return;

		if (bConstraintHit)
			return;

		if (!bCrushing)
			return;
		
		bConstraintHit = true;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedbackEffect, TranslateComp.WorldLocation, true, this, 1800.0, 1200.0);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(CamShakeClass, this, TranslateComp.WorldLocation, 1800.0, 3000.0);

		UMagneticFieldCrusherEffectEventHandler::Trigger_Impact(this);
	}

	UFUNCTION()
	void Activate()
	{
		if (HasControl())
			NetActivateAtTime(Time::GetActorControlCrumbTrailTime(this));
	}

	UFUNCTION(NotBlueprintCallable)
	void Crush()
	{
		TranslateComp.ApplyImpulse(TranslateComp.WorldLocation, TranslateComp.ForwardVector * 1200.0);

		bCrushing = true;
		bConstraintHit = false;

		UMagneticFieldCrusherEffectEventHandler::Trigger_StartCrushing(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void StopCrushing()
	{
		bCrushing = false;

		UMagneticFieldCrusherEffectEventHandler::Trigger_StartRetracting(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			float ConstraintTime = Trajectory::GetTimeToReachTarget(TranslateComp.MaxX, 1200.0, 5500.0);
			float CycleDuration = ConstraintTime + 1.2 + CrushDelay;

			float CycleStartTime = PredictedTimeAtStart;
			if (BurstedTime != 0.0)
				CycleStartTime = BurstedTime - 1.2 - ConstraintTime;

			float CycleTime = Math::Wrap(Time::GetActorControlPredictedCrumbTrailTime(this) - CycleStartTime, 0.0, CycleDuration);

			bool bShouldBeCrushing;
			if (CycleTime < ConstraintTime + 1.2)
				bShouldBeCrushing = true;
			else
				bShouldBeCrushing = false;

			if (bCrushing)
			{
				if (!bShouldBeCrushing)
					StopCrushing();
			}
			else
			{
				if (bShouldBeCrushing)
					Crush();
			}

			if (bCrushing)
				TranslateComp.ApplyForce(TranslateComp.WorldLocation, TranslateComp.ForwardVector * 5500.0);
		}

		if (MagneticFieldResponseComp.WasMagneticallyAffectedThisFrame())
		{
			float MagnetScalar = Math::GetMappedRangeValueClamped(FVector2D(0.0, TranslateComp.MaxX), FVector2D(0.0, 2.0), TranslateComp.RelativeLocation.X);
			TranslateComp.ApplyForce(TranslateComp.WorldLocation, -TranslateComp.ForwardVector * 8000.0 * MagnetScalar);
		}
	}
}

class UMagneticFieldCrusherEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartCrushing() {}
	UFUNCTION(BlueprintEvent)
	void Impact() {}
	UFUNCTION(BlueprintEvent)
	void StartRetracting() {}
	UFUNCTION(BlueprintEvent)
	void FullyRetracted() {}
}