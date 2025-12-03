class AOilRigGrappleSlideContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ContainerRoot;

	UPROPERTY(DefaultComponent, Attach = ContainerRoot)
	UDeathTriggerComponent DeathTrigger;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve MoveCurve;
	UPROPERTY(EditAnywhere)
	float MoveDuration = 12.0;
	UPROPERTY(EditAnywhere)
	float MoveDelay = 0.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 35000;

	float MaxOffset = 28000.0;

	bool bProximityForceFeedbackEnabled = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurTime = Time::PredictedGlobalCrumbTrailTime + MoveDelay;
		float WrappedTime = Math::Wrap(CurTime, 0.0, MoveDuration);

		float Position = MoveCurve.GetFloatValue(Math::Saturate(WrappedTime / MoveDuration));
		float Offset = Math::Lerp(0.0, MaxOffset, Position);
		ContainerRoot.SetRelativeLocation(FVector(Offset, 0.0, 0.0));

		if (bProximityForceFeedbackEnabled)
		{
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(Time::GetGameTimeSeconds() * 30.0) * 0.2;
			FF.RightMotor = Math::Sin(-Time::GetGameTimeSeconds() * 30.0) * 0.2;
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ContainerRoot.WorldLocation, 2500.0, 500.0);
		}
	}

	UFUNCTION()
	void SetProximityForceFeedbackEnabled(bool bEnabled)
	{
		bProximityForceFeedbackEnabled = bEnabled;
	}
}