class ASanctuaryTowersRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.bConstrain = true;
	default RotateComp.ConstrainAngleMin = 0.0;
	default RotateComp.ConstrainAngleMax = 90.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.bWorldSpace = false;
	default ForceComp.Force = FVector::ForwardVector * 300.0;
	default ForceComp.RelativeLocation = FVector::RightVector * -100.0;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

//	UPROPERTY(DefaultComponent)
//	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(EditAnywhere)
	float AngleStep = 90.0;
	float PrevAngle = 0.0;

	UPROPERTY(EditAnywhere)
	float StopTime = 1.0;

	FVector Force;
	FTimerHandle Timer;
	bool bIsRotatingEffectActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		Force = ForceComp.Force;
		RotateComp.ConstrainAngleMin = PrevAngle;
		RotateComp.ConstrainAngleMax = AngleStep;

		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstraintHit");
		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleMinConstraintHit");	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		PrintToScreen("ConstrainAngleMin: " + RotateComp.ConstrainAngleMin, 0.0, FLinearColor::Green);
//		PrintToScreen("ConstrainAngleMax: " + RotateComp.ConstrainAngleMax, 0.0, FLinearColor::Green);
//		PrintToScreen("CurrentRotation: " + Math::RadiansToDegrees(RotateComp.CurrentRotation), 0.0, FLinearColor::Green);

		if (!LightBirdResponseComp.IsIlluminated())
		{
			if (Math::RadiansToDegrees(RotateComp.CurrentRotation) > RotateComp.ConstrainAngleMax - AngleStep * 0.5)
			{
				ForceComp.Force = Force;
			}
			else
			{
				ForceComp.Force = -Force;
			}

			if (bIsRotatingEffectActive && Math::Abs(RotateComp.Velocity) < 0.01 && RotateComp.GetCurrentAlphaBetweenConstraints() <= 0.01)
			{
				UTowerRotatorEffectEventHandler::Trigger_StopRotating(this);
				bIsRotatingEffectActive = false;
			}
		}
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		ForceComp.Force = Force;
		if (!bIsRotatingEffectActive)
			UTowerRotatorEffectEventHandler::Trigger_StartRotating(this);
		bIsRotatingEffectActive = true;
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		ForceComp.Force = -Force;
	}

	UFUNCTION()
	private void HandleMaxConstraintHit(float Strength)
	{
		if (Timer.IsTimerActive())
			return;
		
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		if (bIsRotatingEffectActive)
			UTowerRotatorEffectEventHandler::Trigger_StopRotating(this);
		bIsRotatingEffectActive = false;
		Timer = Timer::SetTimer(this, n"Reactivate", StopTime);
	}

	UFUNCTION()
	private void HandleMinConstraintHit(float Strength)
	{
		if (bIsRotatingEffectActive)
			UTowerRotatorEffectEventHandler::Trigger_StopRotating(this);
		bIsRotatingEffectActive = false;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}	

	UFUNCTION()
	private void Reactivate()
	{
		StepContraint();
	}

	void StepContraint()
	{
		PrevAngle = RotateComp.ConstrainAngleMax;
		RotateComp.ConstrainAngleMin = PrevAngle;
		RotateComp.ConstrainAngleMax = PrevAngle + AngleStep;

		if(LightBirdResponseComp.IsIlluminated() && !bIsRotatingEffectActive)
		{
			UTowerRotatorEffectEventHandler::Trigger_ReactivateRotating(this);		
			bIsRotatingEffectActive = true;
		}
	}
};