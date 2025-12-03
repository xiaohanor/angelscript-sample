class ASanctuaryLakeUnderWaterSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsConeRotateComponent ConeRotate;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	UFauxPhysicsForceComponent ForceCompSidePush;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	UFauxPhysicsConeRotateComponent ClapperRotateComp;

	UPROPERTY(DefaultComponent, Attach = ClapperRotateComp)
	USceneComponent SwingAttachmentRoot;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	USwingPointComponent SwingComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem WaterVFX;

	UPROPERTY(DefaultComponent)
	USceneComponent VFXLocation;

	TPerPlayer<bool> bPlayerAttached;

	bool bIsUnderWater;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandlePortalGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandlePortalReleased");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		SwingComp.OnPlayerAttachedEvent.AddUFunction(this, n"HandleAttached");
		SwingComp.OnPlayerDetachedEvent.AddUFunction(this, n"HandleDetached");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (bPlayerAttached[Player])
			{
				FVector Force = (Player.ActorCenterLocation - ClapperRotateComp.WorldLocation).GetSafeNormal() * 1000.0;
				ClapperRotateComp.ApplyForce(SwingAttachmentRoot.WorldLocation, Force);
				
				UPlayerSwingComponent PlayerSwingComp = UPlayerSwingComponent::Get(Player);
				PlayerSwingComp.SetRopeAttachLocation(SwingAttachmentRoot.WorldLocation);
			}
		}

		if (!bPlayerAttached[Game::Mio] && !bPlayerAttached[Game::Zoe])
		{
			ClapperRotateComp.ApplyForce(SwingAttachmentRoot.WorldLocation, FVector::UpVector * -1000.0);
		}

		UpdateSwingWidgetOffset();


		if(bIsUnderWater != TranslateComp.RelativeLocation.Z < 350)
		{
			SetUnderWater(!bIsUnderWater);
		}

		/*if(TranslateComp.RelativeLocation.Z < 250)
			
		else
			TranslateComp.Friction = 1.0;*/
	}

	void SetUnderWater(bool bNewUnderWater)
	{
		bIsUnderWater = bNewUnderWater;

		if(bIsUnderWater)
		{
			if(TranslateComp.GetVelocity().Z < 200)
			{
				TranslateComp.ApplyImpulse(TranslateComp.WorldLocation, -TranslateComp.GetVelocity() * 0.5);
				Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterVFX, VFXLocation.GetWorldLocation());
				CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
			}
			TranslateComp.Friction = 10.0;		
		}
		else
		{
			TranslateComp.Friction = 1.0;
		}
	}

	private void UpdateSwingWidgetOffset()
	{
		SwingComp.WidgetVisualOffset = SwingAttachmentRoot.WorldLocation - SwingComp.WorldLocation;
	}

	UFUNCTION()
	private void HandleAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		bPlayerAttached[Player] = true;
	}

	UFUNCTION()
	private void HandleDetached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		bPlayerAttached[Player] = false;
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		/*if(HitStrength>2500.0)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterVFX, VFXLocation.GetWorldLocation());
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		}*/
		
	}

	UFUNCTION()
	private void HandlePortalGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		ForceComp.AddDisabler(this);
		ForceCompSidePush.AddDisabler(this);
	}

	UFUNCTION()
	private void HandlePortalReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		ForceComp.RemoveDisabler(this);
	}


};