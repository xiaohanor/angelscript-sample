class ASkylineManekiNeko : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ArmJoint;

	UPROPERTY(DefaultComponent, Attach = ArmJoint)
	UStaticMeshComponent NekoArmLeft;


	UPROPERTY(DefaultComponent, Attach = NekoArmLeft)
	USwingPointComponent SwingPoint;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 25000.0;
	
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve RotationCurve;
	UPROPERTY(EditAnywhere)
	float RotationDuration;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurTime = Time::PredictedGlobalCrumbTrailTime / RotationDuration;
		float WrappedTime = Math::Wrap(CurTime, 0.0, 2.0);
		if (WrappedTime > 1.0)
			WrappedTime = 2.0 - WrappedTime;

		float CurValue = RotationCurve.GetFloatValue(WrappedTime * RotationDuration);
		ArmJoint.RelativeRotation = FRotator(CurValue * -45.0,0.0, 0.0);
	}
};