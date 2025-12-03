class ASanctuaryBossZoeStatueBow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComponent;
	default ForceComponent.Force = FVector::RightVector * 3000.0;
	default ForceComponent.bWorldSpace = false;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UDarkPortalTargetComponent DarkPortalTargetComponent;

	UPROPERTY(DefaultComponent, Attach = LightRoot)
	UCableComponent ArrowString1;

	UPROPERTY(DefaultComponent, Attach = LightRoot)
	UCableComponent ArrowString2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LightRoot;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossZoeBowArrow ProjectileActor;

	UPROPERTY(EditInstanceOnly)
	AFocusCameraActor FocusCamera;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossZoeStatue ZoeStatue;

	UPROPERTY(EditInstanceOnly)
	AStaticCameraActor StaticCamera;

	UPROPERTY(BlueprintReadOnly)
	ASanctuaryLightBirdSocket LightBirdSocket;

	bool bFullyLoaded = false;
	bool bIsLightUp = false;
	bool bFllyUnloaded = true;
	bool bArrowHasFired = false;
	bool bProjectileDetached = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComponent.AddDisabler(this);
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleOnConstrainHit");

//		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleOnGrabbed");
		DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandelOnReleased");
	
		ZoeStatue.OnStatueCompleted.AddUFunction(this, n"HandleStatueAssembled");

		DarkPortalTargetComponent.Disable(this);
		
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedProjectile = Cast<ASanctuaryBossZoeBowArrow>(AttachedActor);
			if (AttachedProjectile != nullptr)
				ProjectileActor = AttachedProjectile;

			auto AttachedLightBirdSocket = Cast<ASanctuaryLightBirdSocket>(AttachedActor);
			if (AttachedLightBirdSocket != nullptr)
				LightBirdSocket = AttachedLightBirdSocket;
		}

		if (LightBirdSocket != nullptr)
		{
			LightBirdSocket.AddDisabler(this);
			LightBirdSocket.AttachToComponent(DarkPortalTargetComponent);
			LightBirdSocket.LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
			LightBirdSocket.LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
			LightBirdSocket.LightBirdResponseComp.OnAttached.AddUFunction(this, n"HandleAttached");
//			LightBirdSocket.LightBirdTargetComp.Disable(this);
			LightBirdSocket.DarkPortalTargetComp.Disable(this);
		}
	}

	UFUNCTION()
	private void HandleAttached()
	{
		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleOnGrabbed");
		
		EnableBow();
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		//DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleOnGrabbed");
		//EnableBow();

		ProjectileActor.Activate();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		//if (DarkPortalResponseComponent.IsGrabbed())
		//	return;

		//DisableBow();
	}

	UFUNCTION()
	private void HandleStatueAssembled()
	{
		LightBirdSocket.RemoveDisabler(this);
//		LightBirdSocket.LightBirdTargetComp.Enable(this);
	}

	void EnableBow()
	{
		DarkPortalTargetComponent.Enable(this);
		LightRoot.SetHiddenInGame(false, true);
		ProjectileActor.SetActorHiddenInGame(false);

		if (ZoeStatue != nullptr && ZoeStatue.AttachedPortal != nullptr && ZoeStatue.AttachedPortal.IsGrabbingActive())
			ZoeStatue.AttachedPortal.Grab(DarkPortalTargetComponent);
	}

	void DisableBow()
	{
		if (bArrowHasFired)
			return;

		DarkPortalTargetComponent.Disable(this);		
		LightRoot.SetHiddenInGame(true, true);

		ProjectileActor.SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void HandleOnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		ForceComponent.RemoveDisabler(this);

		TranslateComp.Friction = 15.0;
		TranslateComp.SpringStrength = 0.0;
		Game::Mio.ActivateCamera(StaticCamera, 2.0, this, EHazeCameraPriority::High);

		// UCameraSettings::GetSettings(Game::Mio).FOV.Apply(90.0, this, Priority = EHazeCameraPriority::High);
		// UCameraSettings::GetSettings(Game::Mio).FOV.Apply(30.0, this, Priority = EHazeCameraPriority::VeryHigh);
		// UCameraSettings::GetSettings(Game::Mio).FOV.SetManualFraction(0, this);

//		Game::Mio.ApplyCameraSettings(CameraSettings, 1.0, this, EHazeCameraPriority::VeryHigh);
//		StaticCameraA.ApplyDefaultSettings(CameraSettings);
	}

	UFUNCTION()
	private void HandelOnReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		ForceComponent.AddDisabler(this);

		TranslateComp.Friction = 5.0;
		TranslateComp.SpringStrength = 600;

		if(bFullyLoaded)
		{
			DoShootArrowThings();
		}

		// if (!LightBirdSocket.LightBirdResponseComp.IsIlluminated())
		// {
		// 	DisableBow();
		// }

		if(!bArrowHasFired)
		{
			Game::Mio.DeactivateCamera(StaticCamera, 4.0);
			UCameraSettings::GetSettings(Game::Mio).FOV.Clear(this);
		}
	}

	void DoShootArrowThings()
	{
		bArrowHasFired = true;
		
		Game::Mio.ActivateCamera(FocusCamera, 1.0, this, EHazeCameraPriority::Cutscene);
		PrintToScreen("AROOWSHOOOT", 2.0);
		ProjectileActor.DetachFromActor(EDetachmentRule::KeepWorld);
	 	ProjectileActor.TimeToShoot();
	}

	UFUNCTION()
	private void HandleOnConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(EFauxPhysicsTranslateConstraintEdge::AxisY_Max == Edge)
		{
			bFullyLoaded=true;

			//ProjectileActor.ArrowMesh.SetHiddenInGame(false);
			//ProjectileActor.ArrowSpinTimeLike.Play();
			//ProjectileActor.GlowingArrowMesh.SetHiddenInGame(false);
		}else{
			bFullyLoaded=false;
		}
		
	}

	void HitTarget()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = TranslateComp.RelativeLocation.Y / TranslateComp.MaxY;
		PrintToScreen("Alpha: " + Alpha, 0.0, FLinearColor::LucBlue);

		UHazeCameraSpringArmSettingsDataAsset Settings;

		StaticCamera.Camera.RelativeLocation = FVector::ForwardVector * (1.0 - Alpha) * -500.0;

		//UCameraSettings::GetSettings(Game::Mio).FOV.SetManualFraction((1.0 - Alpha), this);

		PrintToScreen("FieldOfView: " + StaticCamera.Camera.FieldOfView, 0.0, FLinearColor::LucBlue);
		PrintToScreen("X: " + StaticCamera.Camera.RelativeLocation.X, 0.0, FLinearColor::LucBlue);
	}
};