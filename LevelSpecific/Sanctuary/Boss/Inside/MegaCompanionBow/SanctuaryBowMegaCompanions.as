event void FArrowFullyChargedForVO();

class ASanctuaryBowMegaCompanions : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BowGrabRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent ArrowString1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent ArrowString2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ArrowRoot;

	UPROPERTY(DefaultComponent, Attach = ArrowRoot)
	USceneComponent ArrowSpinRoot;

	UPROPERTY(DefaultComponent, Attach = ArrowSpinRoot)
	UStaticMeshComponent ArrowMesh;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBowLightMegaCompanion LightMegaCompanion;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBowDarkMegaCompanion DarkMegaCompanion;

	UPROPERTY()
	FSanctuaryBowMegaCompanionLightSignature OnMegaExplosion;

	UPROPERTY()
	FSanctuaryBowMegaCompanionLightSignature OnArrowReleased;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor StartCamera;
	FTransform CameraStartTransform;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor EndCamera;
	FTransform CameraEndTransform;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor ArrowCamera;

	UPROPERTY()
	FHazeTimeLike SpawnArrowTimeLike;
	default SpawnArrowTimeLike.UseLinearCurveZeroToOne();
	default SpawnArrowTimeLike.Duration = 0.5;

	bool bGrabbed = false;
	bool bFullyCharged = false;
	bool bArrowAttached = false;
	bool bArrowSpawned = false;
	bool bArrowShot = false;
	bool bArrowIlluminated = false;

	bool bMioPromptShown = false;
	bool bZoePromptShown = false;

	UPROPERTY(BlueprintReadOnly)
	FHazeAcceleratedFloat AccBowGrabForward;
	const float GrabMaxDistance = 3000.0;

	FHazeAcceleratedVector AccRandomGrabOffset;
	FVector RandomGrabTargetOffset;
	const float RandomGrabTargetRadius = 100.0;

	const float HitLocationForwardsOffset = 16500.0;
	FVector ChargeArrowFlyRelativeStartLocation;

	float GrabCoolDown = 1.0;
	float ReleasedTimeStamp;

	FHazeAcceleratedFloat AccCameraAlpha;
	FHazeAcceleratedFloat AccLookAtArrowAlpha;

	UPROPERTY()
	FText TutorialLightText;

	UPROPERTY()
	FArrowFullyChargedForVO OnFullyChargedVO;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkMegaCompanion.OnGrabbed.AddUFunction(this, n"Grab");
		DarkMegaCompanion.OnReleased.AddUFunction(this, n"Release");
		DarkMegaCompanion.BowGrabRoot = BowGrabRoot;
		LightMegaCompanion.OnSpawnArrow.AddUFunction(this, n"HandleSpawnArrow");
		LightMegaCompanion.OnDeSpawnArrow.AddUFunction(this, n"HandleDespawnArrow");
		LightMegaCompanion.OnEnteredSocket.AddUFunction(this, n"HandleEnteredSocket");
		SpawnArrowTimeLike.BindUpdate(this, n"SpawnArrowTimeLikeUpdate");
		SpawnArrowTimeLike.BindFinished(this, n"SpawnArrowTimeLikeFinished");

		CameraStartTransform = StartCamera.ActorTransform;
		CameraEndTransform = EndCamera.ActorTransform;

		AccCameraAlpha.SnapTo(0.0);
		AccLookAtArrowAlpha.SnapTo(0.0);

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bGrabbed && ReleasedTimeStamp + GrabCoolDown < Time::GameTimeSeconds && bArrowSpawned)
		{
			AccBowGrabForward.ThrustTo(GrabMaxDistance, 300.0, DeltaSeconds);
			//AccBowGrabForward.AccelerateToWithStop(GrabMaxDistance, 5.0, DeltaSeconds, KINDA_SMALL_NUMBER);

			if (Math::IsNearlyEqual(AccBowGrabForward.Value, GrabMaxDistance) && !bFullyCharged)
			{
				FullyCharged();
			}

			AccCameraAlpha.AccelerateTo(AccBowGrabForward.Value / GrabMaxDistance, 1.0, DeltaSeconds);
		}	
		else
		{
			AccBowGrabForward.SpringTo(0.0, 200.0, 0.3, DeltaSeconds);

			if (bArrowAttached && AccBowGrabForward.Value < 0.0 && bArrowSpawned)
				DetachArrow();

			if (!bFullyCharged)
			{
				AccCameraAlpha.AccelerateTo(0.0, 5.0, DeltaSeconds);
			}
			else
			{
				AccLookAtArrowAlpha.AccelerateTo(1.0, 2.0, DeltaSeconds);
			}
		}

		if (bArrowAttached)
		{
			FVector GrabRootDirection = (ActorLocation - BowGrabRoot.WorldLocation).GetSafeNormal();
			FRotator ArrowRotation = GrabRootDirection.ToOrientationRotator();
			ArrowRoot.SetWorldRotation(ArrowRotation);
			ArrowSpinRoot.AddRelativeRotation(FRotator(0.0, 0.0, 1000.0 * DeltaSeconds));
		}

		float FFStrength = AccBowGrabForward.Value / GrabMaxDistance * 1.0;
		Game::Zoe.SetFrameForceFeedback(FFStrength, FFStrength, FFStrength, FFStrength);
		Game::Mio.SetFrameForceFeedback(FFStrength, FFStrength, FFStrength, FFStrength);

		AccRandomGrabOffset.AccelerateTo(RandomGrabTargetOffset, 1.0, DeltaSeconds);

		BowGrabRoot.SetRelativeLocation(FVector::ForwardVector * -AccBowGrabForward.Value + AccRandomGrabOffset.Value * (AccBowGrabForward.Value / GrabMaxDistance));
		DarkMegaCompanion.BP_GrabUpdate(BowGrabRoot.WorldLocation);

		FTransform CameraTransform;

		CameraTransform.Location = Math::Lerp(
			CameraStartTransform.Location, 
			CameraEndTransform.Location, 
			AccCameraAlpha.Value);

		

		FRotator EndCameraRotation = Math::LerpShortestPath(
			CameraStartTransform.Rotation.Rotator(),
			CameraEndTransform.Rotation.Rotator(),
			AccCameraAlpha.Value);

		FRotator LookAtArrowRotation = (ArrowRoot.WorldLocation - CameraEndTransform.Location).GetSafeNormal().Rotation();

		CameraTransform.Rotation = Math::LerpShortestPath(
			EndCameraRotation,
			LookAtArrowRotation,
			AccLookAtArrowAlpha.Value).Quaternion();

		StartCamera.SetActorTransform(CameraTransform);
		UCameraSettings::GetSettings(Game::Mio).FOV.SetManualFraction((AccCameraAlpha.Value - AccLookAtArrowAlpha.Value), this);
	}

	UFUNCTION()
	private void HandleEnteredSocket()
	{
		LightMegaCompanion.SetActorLocationAndRotation(ActorLocation, ActorRotation);
		Game::Mio.ActivateCamera(StartCamera, 4.0, this, EHazeCameraPriority::VeryHigh);
		BP_EnteredSocket();
		ShowMioPrompt();

		UCameraSettings::GetSettings(Game::Mio).FOV.Apply(40.0, Game::Mio, Priority = EHazeCameraPriority::High);
		UCameraSettings::GetSettings(Game::Mio).FOV.Apply(50.0, this, Priority = EHazeCameraPriority::VeryHigh);
		UCameraSettings::GetSettings(Game::Mio).FOV.SetManualFraction(0, this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_EnteredSocket(){}

	UFUNCTION()
	private void HandleSpawnArrow()
	{
		if (bArrowShot)
			return;
		if (bArrowIlluminated)
			return;

		bool bIsMioControl = Game::Mio.HasControl(); // Mio is light bird player and spawns arrow
		if (bIsMioControl)
			CrumbSpawnArrow();	
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnArrow()
	{
		SpawnArrowTimeLike.Play();
		
		HideMioPrompt();	

		bArrowIlluminated = true;

		if (!bGrabbed)
			ShowZoePrompt();
	}

	UFUNCTION()
	private void HandleDespawnArrow()
	{
		if (bArrowShot)
			return;
		if (!bArrowIlluminated)
			return;
		if (HasControl())
			CrumbDespawnArrow();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDespawnArrow()
	{
		SpawnArrowTimeLike.Reverse();
		bArrowSpawned = false;
		bFullyCharged = false;
		bArrowIlluminated = false;


		HideZoePrompt();
		ShowMioPrompt();

		if (bArrowAttached)
		{
			bArrowAttached = false;
			ArrowRoot.AttachToComponent(Root, NAME_None, EAttachmentRule::SnapToTarget);
		}
	}

	UFUNCTION()
	private void SpawnArrowTimeLikeUpdate(float CurrentValue)
	{
		BP_SpawningArrowUpdate(CurrentValue);
		ArrowRoot.SetRelativeRotation(FRotator(0.0, 0.0, CurrentValue * 360.0));
	}

	UFUNCTION()
	private void SpawnArrowTimeLikeFinished()
	{
		if (!SpawnArrowTimeLike.IsReversed())
		{
			BP_SpawnArrowFinished();
			bArrowSpawned = true;
		}
		else
		{	
			AccBowGrabForward.SnapTo(0.0);
		}
	}

	UFUNCTION()
	void Grab()
	{
		if (bArrowShot)
			return;

		AccBowGrabForward.SnapTo(AccBowGrabForward.Value);
		bGrabbed = true;

		if (bArrowSpawned)
		{
			HideZoePrompt();
			HideMioPrompt();
		}
	}

	UFUNCTION()
	void Release()
	{
		if (bArrowShot)
			return;
		
		bGrabbed = false;

		if (bFullyCharged && HasControl())
		{
			CrumbShootArrow();
		}

		else if (bArrowSpawned)
		{
			ShowMioPrompt();
			ShowZoePrompt();
		}

		if (ReleasedTimeStamp + GrabCoolDown < Time::GameTimeSeconds)
			ReleasedTimeStamp = Time::GameTimeSeconds;
	}

	private void FullyCharged()
	{
		bFullyCharged = true;
		bArrowAttached = true;
		SetRandomOffset();
		OnFullyChargedVO.Broadcast();
	}

	UFUNCTION()
	private void SetRandomOffset()
	{
		RandomGrabTargetOffset = Math::GetRandomPointOnSphere() * RandomGrabTargetRadius;
		Timer::SetTimer(this, n"SetRandomOffset", 0.2);
	}

	UFUNCTION(CrumbFunction)
	void CrumbShootArrow()
	{
		//bFullyCharged = false;
		BP_ShootArrow();

		bArrowShot = true;
		
		ArrowRoot.AttachToComponent(BowGrabRoot, NAME_None, EAttachmentRule::KeepWorld);

		Timer::ClearTimer(this, n"SetRandomOffset");
		RandomGrabTargetOffset = FVector::ZeroVector;

		Time::SetWorldTimeDilation(0.3);
		Game::Mio.ActivateCamera(ArrowCamera, 0.5, this, EHazeCameraPriority::Cutscene);

		OnArrowReleased.Broadcast();
	}
	
	void DetachArrow()
	{
		bArrowAttached = false;
		ArrowRoot.AttachToComponent(Root, NAME_None, EAttachmentRule::KeepWorld);
		ArrowRoot.SetWorldRotation(ActorForwardVector.Rotation());
		ChargeArrowFlyRelativeStartLocation = ActorTransform.InverseTransformPositionNoScale(ArrowRoot.WorldLocation);

		QueueComp.Empty();
	 	QueueComp.Duration(0.15, this, n"ChargeArrowFlyUpdate");
	 	QueueComp.Event(this, n"ArrowExplode");
	}

	UFUNCTION()
	private void ChargeArrowFlyUpdate(float Alpha)
	{
		FVector RelativeArrowLocation = Math::Lerp(ChargeArrowFlyRelativeStartLocation, FVector::ForwardVector * HitLocationForwardsOffset, Alpha);
		ArrowRoot.SetRelativeLocation(RelativeArrowLocation);
		ArrowSpinRoot.SetRelativeRotation(FRotator(0.0, 0.0, 1000.0 * Alpha));
	}

	UFUNCTION()
	private void ArrowExplode()
	{
		BP_ArrowExplode();
		OnMegaExplosion.Broadcast();
		Time::SetWorldTimeDilation(1.0);
		Game::Mio.DeactivateCameraByInstigator(this);

		SetActorHiddenInGame(true);
	}

	private void ShowMioPrompt()
	{
		if (bMioPromptShown)
			return;

		FTutorialPrompt LightTutorial;
		LightTutorial.Action = ActionNames::SecondaryLevelAbility;
		LightTutorial.Text = TutorialLightText;
		LightTutorial.DisplayType = ETutorialPromptDisplay::ActionHold;
		Game::Mio.ShowTutorialPromptWorldSpace(LightTutorial, this, LightMegaCompanion.Root, FVector(0.0, 0.0, 150.0));
		
		bMioPromptShown = true;
	}

	private void HideMioPrompt()
	{
		Game::Mio.RemoveTutorialPromptByInstigator(this);
		bMioPromptShown = false;
	}

	private void ShowZoePrompt()
	{
		if (bZoePromptShown)
			return;

		FTutorialPrompt PortalTutorial;
		PortalTutorial.Action = ActionNames::SecondaryLevelAbility;
		PortalTutorial.Text = NSLOCTEXT("SanctuaryHydra", "DarkCompanionGrabBow", "Grab");
		PortalTutorial.DisplayType = ETutorialPromptDisplay::ActionHold;
		Game::Zoe.ShowTutorialPromptWorldSpace(PortalTutorial, this, DarkMegaCompanion.PortalRoot, FVector(0.0, 0.0, 150.0));

		bZoePromptShown = true;
	}

	private void HideZoePrompt()
	{
		Game::Zoe.RemoveTutorialPromptByInstigator(this);
		bZoePromptShown = false;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawnArrow(){}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawningArrowUpdate(float Alpha){}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawnArrowFinished(){}
	
	UFUNCTION(BlueprintEvent)
	private void BP_DeSpawnArrow(){}

	UFUNCTION(BlueprintEvent)
	private void BP_ShootArrow(){}

	UFUNCTION(BlueprintEvent)
	private void BP_ArrowExplode(){}
};