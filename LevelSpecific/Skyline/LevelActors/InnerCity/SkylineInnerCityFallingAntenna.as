event void FAntennaFallEvent();
class ASkylineInnerCityFallingAntenna : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.LocalRotationAxis = FVector::RightVector;
	default RotateComp.Friction = 1.5;
	default RotateComp.ConstrainBounce = 0.2;
	default RotateComp.bConstrain = true;
	default RotateComp.ConstrainAngleMin = 0.0;
	default RotateComp.ConstrainAngleMax = 94.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceCompGravity;
	default ForceCompGravity.Force = -FVector::UpVector * 100.0;
	default ForceCompGravity.RelativeLocation = FVector::UpVector * 5000.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceCompPush;
	default ForceCompPush.Force = FVector::ForwardVector * 50.0;
	default ForceCompPush.bWorldSpace = false;
	default ForceCompPush.RelativeLocation = FVector::UpVector * 5000.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY()
	FAntennaFallEvent OnAntennaFall;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	bool bDoOnce = true;

	UPROPERTY(EditAnywhere)
	ADeathVolume Deathvolume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateComp.AddDisabler(this);
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleConstrainHit(float Strength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		if(bDoOnce)
		{
			bDoOnce = false;
			Timer::SetTimer(this, n"HandleDealyedDeathVolumeActivated", 0.6);
			BP_AntennaHitGround();
			USkylineInnerCityFallingAntennaEventHandler::Trigger_OnGroundImpact(this);
		}
	}

	UFUNCTION()
	private void HandleDealyedDeathVolumeActivated()
	{
		Deathvolume.AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Fall();
		
		OnAntennaFall.Broadcast();
		USkylineInnerCityFallingAntennaEventHandler::Trigger_OnStartFall(this);
	}
	
	UFUNCTION(BlueprintCallable)
	void StartFallenDown()
	{
		RotateComp.SetRelativeRotation(FRotator(-90.4 ,0.0, 0.0,));
		Timer::SetTimer(this, n"StartFallenDownDelay", 0.1);
	}

	UFUNCTION(BlueprintEvent)
	void BP_AntennaHitGround()
	{}

	UFUNCTION()
	private void StartFallenDownDelay()
	{
		RotateComp.SetRelativeRotation(FRotator(-90.5 ,0.0, 0.0,));
		Deathvolume.DisableDeathVolume(this);
	}

	UFUNCTION()
	void Fall()
	{
		RotateComp.RemoveDisabler(this);
	}
};