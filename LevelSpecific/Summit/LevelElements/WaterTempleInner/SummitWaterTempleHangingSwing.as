class ASummitWaterTempleHangingSwing : AHazeActor
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
	UFauxPhysicsConeRotateComponent ClapperRotateComp;

	UPROPERTY(DefaultComponent, Attach = ClapperRotateComp)
	USceneComponent SwingAttachmentRoot;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	USwingPointComponent SwingComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem WaterVFX;

	UPROPERTY(DefaultComponent)
	USceneComponent VFXLocation;

	TPerPlayer<bool> bPlayerAttached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
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
		//PrintToScreen("HitStrength" + HitStrength, 2.0);

		/*if(HitStrength>2500.0)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterVFX, VFXLocation.GetWorldLocation());
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		}*/
		
	}

};