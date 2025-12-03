class ASkylineTankerTruckBladeHatch : ASkylineGravityBladeTrigger
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent TranslateForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsConeRotateComponent ConeRotateComp;	

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent RotateForceComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	bool bIsOpen = false;
	bool bDoOnce = false;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TranslateForceComp.AddDisabler(this);
		RotateForceComp.AddDisabler(this);
		ConeRotateComp.AddDisabler(this);
		PlayerWeightComp.AddDisabler(this);

		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleRotateConstrain");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleTranslateConstrainHit");

		Animation.BindUpdate(this, n"HandleAnimationUpdate");
		Animation.BindFinished(this, n"HandleAnimationFinished");
	}

	UFUNCTION()
	private void HandleAnimationUpdate(float CurrentValue)
	{
		BP_AnimationUpdate(CurrentValue);
	}
	
	UFUNCTION()
	private void HandleAnimationFinished()
	{
		Open();
	}

	UFUNCTION()
	private void HandleRotateConstrain(float Strength)
	{
		if(!bDoOnce)
		{
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
			bDoOnce = true;
		}
		
	}

	UFUNCTION()
	private void HandleTranslateConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Max)
		{
			RotateForceComp.RemoveDisabler(this);
			ConeRotateComp.RemoveDisabler(this);
			PlayerWeightComp.RemoveDisabler(this);		
		}
	}

	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData) override
	{
		if (bIsOpen)
			return;

		Animation.Play();

		bIsOpen = true;

		Disable();

		if (bIsReady)
		{
			if (bToggle)
			{
				if (!bIsActivated)
					Activate();
				else
					Deactivate();
			}
			else
				Activate();
		}

		BP_OnHit(HitData);
	}

	void Open()
	{
		bIsOpen = true;

		TranslateForceComp.RemoveDisabler(this);
	
		BP_OnOpen();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnOpen() { }

	UFUNCTION(BlueprintEvent)
	void BP_AnimationUpdate(float CurrentValue) { }
};