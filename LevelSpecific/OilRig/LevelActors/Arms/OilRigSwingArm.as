class AOilRigSwingArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	USceneComponent SwivelRoot;

	UPROPERTY(DefaultComponent, Attach = SwivelRoot)
	USceneComponent ElbowRoot;

	UPROPERTY(DefaultComponent, Attach = ElbowRoot)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent SwingRoot;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	USwingPointComponent SwingPointComp;

	UPROPERTY(EditAnywhere)
	float CableLength = 1600.0;
	
	UPROPERTY(EditAnywhere, Category = "Rotation")
	FRuntimeFloatCurve RotationCurve;
	UPROPERTY(EditAnywhere, Category = "Rotation")
	float RotationDuration = 6.0;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	FVector2D RotationRange = FVector2D(0.0, 180.0);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	bool bActive = false;
	float StartRotatingTime = 0.0;

	float PreviousValue = 0.0;
	bool bRotating = false;

	int Direction = 1;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	UFUNCTION()
	void RevealArm()
	{
		BP_RevealArm();

		UOilRigSwingArmEffecttHandler::Trigger_Activated(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_RevealArm() {}

	UFUNCTION()
	void StartRotating()
	{
		bActive = true;
		StartRotatingTime = Time::PredictedGlobalCrumbTrailTime;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;

		float CurTime = (Time::PredictedGlobalCrumbTrailTime - StartRotatingTime) / RotationDuration;
		float WrappedTime = Math::Wrap(CurTime, 0.0, 2.0);
		if (WrappedTime > 1.0)
			WrappedTime = 2.0 - WrappedTime;

		float CurValue = RotationCurve.GetFloatValue(WrappedTime);

		float Rot = Math::Lerp(RotationRange.X, RotationRange.Y, CurValue);
		SwivelRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));

		if (Direction == 0 && PreviousValue > CurValue)
		{
			Direction = 1;
			UOilRigSwingArmEffecttHandler::Trigger_StartMove(this);
		}
		else if (Direction == 1 && CurValue > PreviousValue)
		{
			Direction = 0;
			UOilRigSwingArmEffecttHandler::Trigger_StartMove(this);
		}

		PreviousValue = CurValue;
	}
}

class UOilRigSwingArmEffecttHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Activated() {}

	UFUNCTION(BlueprintEvent)
	void StartMove() {}
}