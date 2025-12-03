class ASanctuaryTowersPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MaxZ = 1000.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.bWorldSpace = false;
	default ForceComp.Force = FVector::DownVector * 2000.0;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		FlipForce();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		FlipForce();
	}

	void FlipForce()
	{
		ForceComp.Force *= -1.0;
	}
};