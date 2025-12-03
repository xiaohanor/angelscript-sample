UCLASS(Abstract)
class AIslandShootableSpinningTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent ShootableMesh;

	UPROPERTY(DefaultComponent, Attach = ShootableMesh)
	UIslandRedBlueImpactResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SpinCurve;
	default SpinCurve.AddDefaultKey(0.0, 0.0);
	default SpinCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float SpinDuration = 0.3;

	bool bActivated = false;
	bool bAtStartRot = true;
	bool bClockwiseRotate = true;
	float TargetRotation = 180;
	float StartRotation = 0;
	float TimeSpinStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bActivated)
		{
			float RotationAlpha = Math::GetPercentageBetween(TimeSpinStarted, TimeSpinStarted + SpinDuration, Time::GetGameTimeSeconds());

			RotationAlpha = Math::Saturate(RotationAlpha);

			float LerpedPitch = Math::LerpAngleDegreesInDirection(StartRotation, TargetRotation, SpinCurve.GetFloatValue(RotationAlpha), bClockwiseRotate);

			RotationRoot.SetRelativeRotation(FRotator(LerpedPitch, 0, 0 ));

			if(RotationAlpha == 1)
			{
				bActivated = false;
				bAtStartRot = bAtStartRot ? false : true;
				UShootableSpinningTargetEventHandler::Trigger_OnSpinStop(this);
				CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
			}
		}
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(bActivated)
			return;
		
		
		PerformSpin(Data.ImpactNormal);

		UShootableSpinningTargetEventHandler::Trigger_OnSpinStart(this);

		// VO
		if (Data.Player != nullptr)
			UShootableSpinningTargetEventHandler::Trigger_OnSpinStart(Data.Player);

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	void PerformSpin(FVector ImpactNormal)
	{
		float ImpactDotProduct = ActorForwardVector.DotProduct(ImpactNormal);
		bool bImpactForward = ImpactDotProduct > 0;
		bClockwiseRotate = true;

		TimeSpinStarted = Time::GetGameTimeSeconds();

		if(bAtStartRot)
		{
			if(!bImpactForward)
			{
				bClockwiseRotate = false;
			}
		}
		else
		{
			if(bImpactForward)
			{
				bClockwiseRotate = false;
			}
		}

		StartRotation = bAtStartRot ? 0 : 180;
		TargetRotation = bAtStartRot ? 180 : 0;

		bActivated = true;
	}
};
