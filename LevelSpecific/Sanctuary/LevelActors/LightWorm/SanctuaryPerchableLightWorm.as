class ASanctuaryGrappleLaunchLightWorm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent MovementForce;
	default MovementForce.Force = FVector::UpVector * -500.0;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	FHazeTimeLike MovementForceTimeLike;
	default MovementForceTimeLike.UseLinearCurveZeroToOne();
	default MovementForceTimeLike.Duration = 1.0;

	bool bAboveWater = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		MovementForceTimeLike.BindUpdate(this, n"MovementForceTimeLikeUpdate");
	}

	UFUNCTION()
	private void MovementForceTimeLikeUpdate(float CurrentValue)
	{
		MovementForce.Force = FVector::UpVector * Math::Lerp(-500.0, 1000.0, CurrentValue);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		MovementForceTimeLike.Play();
	}
	
	UFUNCTION()
	private void HandleUnilluminated()
	{
		MovementForceTimeLike.Reverse();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TranslateComp.RelativeLocation.Z > VFXComp.RelativeLocation.Z && !bAboveWater)
		{
			bAboveWater = true;
			VFXComp.Activate(true);
		}

		if (TranslateComp.RelativeLocation.Z < VFXComp.RelativeLocation.Z && bAboveWater)
			bAboveWater = false;
	}
};