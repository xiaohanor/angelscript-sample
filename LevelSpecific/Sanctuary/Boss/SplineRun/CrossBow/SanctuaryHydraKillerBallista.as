event void FSanctuaryHydraKillerBallistaSignature();
event void FSanctuaryHydraKillerBallistaInteractSignature(AHazePlayerCharacter LastInteractingPlayer);

class ASanctuaryHydraKillerBallista : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UHazeSphereCollisionComponent TriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateYawRoot;

	UPROPERTY(DefaultComponent, Attach = RotateYawRoot)
	USceneComponent ImpulseRoot;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	USceneComponent WheelLeftBack;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	USceneComponent WheelRightBack;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	USceneComponent WheelLeftFront;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	USceneComponent WheelRightFront;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	UFauxPhysicsAxisRotateComponent PitchRotateComp;

	UPROPERTY(DefaultComponent, Attach = PitchRotateComp)
	USceneComponent CrankRotateComp;

	UPROPERTY(DefaultComponent, Attach = PitchRotateComp)
	USceneComponent HookRootComp;

	UPROPERTY(DefaultComponent, Attach = PitchRotateComp)
	USceneComponent LauncherRootComp;

	UPROPERTY(DefaultComponent, Attach = LauncherRootComp)
	USceneComponent LauncherWheelRootComp;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	UThreeShotInteractionComponent ZoeInteractComp;

	UPROPERTY(DefaultComponent, Attach = ImpulseRoot)
	UThreeShotInteractionComponent MioInteractComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossStopSplineRunComponent StopSplineRunComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryBossStopSplineRunCapability");

	UPROPERTY(EditAnywhere)
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.bAllowPlayerCancel = false;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ImpulseTimeLike;
	default ImpulseTimeLike.UseSmoothCurveZeroToOne();
	default ImpulseTimeLike.Duration = 1.0;

	UPROPERTY(EditAnywhere)
	float TotalRotation = -1000.0;
	
	UPROPERTY(EditAnywhere)
	float Stiff = 100.0;

	UPROPERTY(EditAnywhere)
	float Damp = 0.3;

	UPROPERTY(EditAnywhere)
	bool bInfuseArrow = false;

	UPROPERTY(EditAnywhere)
	float ImpulseDistance = 200.0;

	UPROPERTY(EditDefaultsOnly)
	UAnimationAsset MioInteractPreviewAnim;
	UPROPERTY(EditDefaultsOnly)
	UAnimationAsset ZoeInteractPreviewAnim;

	UPROPERTY()
	UCurveFloat RotateCurve;

	UPROPERTY()
	FHazeTimeLike PrepareLaunchTimeLike;
	default PrepareLaunchTimeLike.UseSmoothCurveZeroToOne();
	default PrepareLaunchTimeLike.Duration = 1.5;

	UPROPERTY()
	float FireDelay = 0.5;

	UPROPERTY()
	float InfuseFireDelay = 2.5;

	UPROPERTY(EditInstanceOnly)
	bool bUnCompletable = false;

	UPROPERTY()
	FSanctuaryHydraKillerBallistaInteractSignature OnBothPlayersInteracting;

	UPROPERTY()
	FSanctuaryHydraKillerBallistaSignature OnMashCompleted;

	UPROPERTY()
	FSanctuaryHydraKillerBallistaSignature OnCanceled;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureBallistaInteract MioPlayerLocoFeature;
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureBallistaInteract ZoePlayerLocoFeature;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	TPerPlayer<bool> bInteracting;
	TPerPlayer<UButtonMashComponent> MashComp;
	TPerPlayer<float> MashProgress;

	FHazeAcceleratedFloat AcceleratedProgress;
	ASanctuaryBossSplineRunPlatform Platform;

	bool bBothInteracting = false;
	float TotalProgress = 0.0;
	float CombinedProgress = 0.0;
	bool bFired = false;
	bool bProjectileDetached = false;
	bool bInteractionCompleted = false;
	bool bInteractionStarted = false;

	const float BackWheelRotMult = 3.0;
	const float FrontWheelRotMult = 3.0;

	FHazeAcceleratedFloat AcceleratedYaw;

	FHazeAcceleratedFloat AcceleratedFireFloat;

	ASanctuaryHydraKillerBallistaProjectile ProjectileActor;

	USanctuaryHydraKillerBallistaPlayerAnimationComponent MioInteractAnimComp;
	bool bMioRequestAnim = false;
	USanctuaryHydraKillerBallistaPlayerAnimationComponent ZoeInteractAnimComp;
	bool bZoeRequestAnim = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		VisualizePlayerInteract(EHazePlayer::Mio, MioInteractComp, MioInteractPreviewAnim);
		VisualizePlayerInteract(EHazePlayer::Zoe, ZoeInteractComp, ZoeInteractPreviewAnim);
	}

	private void VisualizePlayerInteract(EHazePlayer SelectedPlayer, UThreeShotInteractionComponent InteractyComp, UAnimationAsset AnimToPlay)
	{
		auto VisMesh = CreatePlayerEditorVisualizer(InteractyComp, SelectedPlayer, FTransform::Identity);
		if (AnimToPlay != nullptr)
		{
			VisMesh.AnimationMode = EAnimationMode::AnimationSingleNode;
			VisMesh.AnimationData.AnimToPlay = AnimToPlay;
			VisMesh.RefreshEditorPose();
		}
		CreateInteractionEditorVisualizer(InteractyComp, InteractyComp.UsableByPlayers);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ZoeInteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		ZoeInteractComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		MioInteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		MioInteractComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		PrepareLaunchTimeLike.BindUpdate(this, n"PrepareLaunchTimeLikeUpdate");
		PrepareLaunchTimeLike.BindFinished(this, n"PrepareLaunchTimeLikeFinished");
		ImpulseTimeLike.BindUpdate(this, n"ImpulseTimeLikeUpdate");
		ImpulseTimeLike.BindFinished(this, n"ImpulseTimeLikeFinished");
		// TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");

		AcceleratedFireFloat.SnapTo(1.0);

		Platform = Cast<ASanctuaryBossSplineRunPlatform>(AttachParentActor);

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);

		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedProjectile = Cast<ASanctuaryHydraKillerBallistaProjectile>(AttachedActor);
			if (AttachedProjectile != nullptr)
				ProjectileActor = AttachedProjectile;
		}

		MioInteractAnimComp = USanctuaryHydraKillerBallistaPlayerAnimationComponent::GetOrCreate(Game::Mio);
		ZoeInteractAnimComp = USanctuaryHydraKillerBallistaPlayerAnimationComponent::GetOrCreate(Game::Zoe);

		KillerBallistaDevToggles::KillerBallistaCategory.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bBothInteracting)
		{
			for (auto Player : Game::GetPlayers())
			{
				MashProgress[Player] = MashComp[Player].GetButtonMashProgress(this);
			}

			CombinedProgress = (MashProgress[Game::Mio] + MashProgress[Game::Zoe]) * 0.5;

			//if (CombinedProgress > TotalProgress)
			TotalProgress = CombinedProgress;
	
			if (Math::IsNearlyEqual(TotalProgress, 1.0, KINDA_SMALL_NUMBER) && !bUnCompletable)
			{
				if (HasControl())
					NetInteractionCompleted();
			}
		}

		if (bBothInteracting && bInfuseArrow)
		{
			FVector TargetRelativeLocation = ActorTransform.InverseTransformPositionNoScale(ProjectileActor.GetTargetLocation());
			FRotator TargetRotation = (TargetRelativeLocation).VectorPlaneProject(FVector::UpVector).Rotation();
			AcceleratedYaw.AccelerateTo(TargetRotation.Yaw * 1.0, 6.0, DeltaSeconds);
			RotateYawRoot.SetRelativeRotation(FRotator(0.0, AcceleratedYaw.Value, 0.0));

			WheelLeftFront.SetRelativeRotation(FRotator(0.0, -90.0, AcceleratedYaw.Value * -FrontWheelRotMult));
			WheelLeftBack.SetRelativeRotation(FRotator(0.0, -90.0, AcceleratedYaw.Value * -BackWheelRotMult));
			WheelRightFront.SetRelativeRotation(FRotator(0.0, -90.0, AcceleratedYaw.Value * FrontWheelRotMult));
			WheelRightBack.SetRelativeRotation(FRotator(0.0, -90.0, AcceleratedYaw.Value * BackWheelRotMult));
		}

		if (!bInteractionCompleted && bInteractionStarted)
		{
			FVector BackwardsLocation = FVector::ForwardVector * -600.0 * GetAcceleratedAbsProgress();			

			HookRootComp.SetRelativeLocation(BackwardsLocation);
			LauncherRootComp.SetRelativeLocation(BackwardsLocation);
			LauncherWheelRootComp.SetRelativeRotation(FRotator(GetAcceleratedAbsProgress() * 500.0, 0.0, 0.0));
			CrankRotateComp.SetRelativeRotation(FRotator(GetAcceleratedAbsProgress() * TotalRotation, 0.0, 0.0));

			if (KillerBallistaDevToggles::DebugCrank.IsEnabled())
			{
				const float TotDebugDur = 3.0;
				float WrappedTime = Math::Saturate(Math::Wrap(Time::GameTimeSeconds, 0.0, TotDebugDur) / TotDebugDur);
				float FakeProgress = AlphaStatics::FrequencyAlpha(WrappedTime);
				AcceleratedProgress.SnapTo(FakeProgress);
			}
			else
				AcceleratedProgress.AccelerateTo(TotalProgress, 0.5, DeltaSeconds);

		}

		if (bFired)
		{
			AcceleratedFireFloat.SpringTo(0.0, Stiff, Damp, DeltaSeconds);

			if (AcceleratedFireFloat.Value < 0.0 && !bProjectileDetached)
			{
				bProjectileDetached = true;
				ProjectileActor.DetachFromActor(EDetachmentRule::KeepWorld);
				ProjectileActor.Fire(AcceleratedFireFloat.Velocity * -2000.0);
			}
			
			float Alpha = Math::Abs(AcceleratedFireFloat.Value);

			FVector NewLocation = FVector(-600.0 * Alpha, 0.0, -30.0);
			LauncherRootComp.SetRelativeLocation(NewLocation);

			float RotateAlpha = RotateCurve.GetFloatValue(PrepareLaunchTimeLike.GetPosition());
			HookRootComp.SetRelativeRotation(FRotator(RotateAlpha * -90.0, 0.0, 0.0));
		}

		bool bCancelSpringBack = !bBothInteracting && !bInfuseArrow && !bInteractionCompleted && !bInteractionStarted && !bFired;
		if (bCancelSpringBack || bFired)
		{
			FVector BackwardsLocation = FVector::ForwardVector * -600.0 * GetAcceleratedAbsProgress();			
			HookRootComp.SetRelativeLocation(BackwardsLocation);
			LauncherRootComp.SetRelativeLocation(BackwardsLocation);
			LauncherWheelRootComp.SetRelativeRotation(FRotator(GetAcceleratedAbsProgress() * 500.0, 0.0, 0.0));
			CrankRotateComp.SetRelativeRotation(FRotator(GetAcceleratedAbsProgress() * TotalRotation, 0.0, 0.0));
			AcceleratedProgress.SpringTo(0.0, 300.0, 0.8, DeltaSeconds);
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			// float PlayerCrankRot = Math::Wrap(, 0.0, 360.0);
			// PlayerCrankRot += Player.IsMio() ? 180 : 0.0;
			// const float CrankAnimationMaxDegrees = 359.0;
			// const float PlayerCrankAlpha = Math::Saturate(Math::Wrap(PlayerCrankRot, 0.0, CrankAnimationMaxDegrees) / CrankAnimationMaxDegrees);
			// TEMPORAL_LOG(this, "Animation").Value("Crank Rot Alpha " + Player.ActorNameOrLabel, PlayerCrankAlpha);
			const float CurrentDegrees = Math::Wrap(GetAcceleratedAbsProgress() * TotalRotation, 0.0, 360.0);
			const float CurrentCrankAlpha = Math::Saturate(CurrentDegrees / 360.0);

			if (Player.IsMio())
			{
				if (bMioRequestAnim)
				{
					if (Player.Mesh.CanRequestLocomotion())
						Player.RequestLocomotion(n"BallistaInteract", this);
					MioInteractAnimComp.BallistaRotationSpeed = AcceleratedYaw.Velocity;
					MioInteractAnimComp.LeverTurnProgress = CurrentCrankAlpha;//Math::GetMappedRangeValueClamped(FVector2D(-90, 90), FVector2D(0.0, 1.0), CrankRotateComp.RelativeRotation.Pitch);
					MioInteractAnimComp.bIsStruggling = Math::IsNearlyEqual(MashProgress[Player], 1.0, KINDA_SMALL_NUMBER) && !bInteractionCompleted;
					MioInteractAnimComp.bIsFinished = bInteractionCompleted;
				}
			}
			if (Player.IsZoe())
			{
				if (bZoeRequestAnim)
				{
					if (Player.Mesh.CanRequestLocomotion())
						Player.RequestLocomotion(n"BallistaInteract", this);
					ZoeInteractAnimComp.BallistaRotationSpeed = AcceleratedYaw.Velocity;
					ZoeInteractAnimComp.LeverTurnProgress = CurrentCrankAlpha;//GetAcceleratedAbsProgress();
					ZoeInteractAnimComp.bIsStruggling = Math::IsNearlyEqual(MashProgress[Player], 1.0, KINDA_SMALL_NUMBER) && !bInteractionCompleted;
					ZoeInteractAnimComp.bIsFinished = bInteractionCompleted;
				}
			}
		}
		TEMPORAL_LOG(this, "Animation").Value("Rot Crank", CrankRotateComp.RelativeRotation);
		TEMPORAL_LOG(this, "Animation").Value("Rot Velocity", AcceleratedYaw.Velocity);
		TEMPORAL_LOG(this, "Animation").Value("Acc Progress", GetAcceleratedAbsProgress());
	}

		
	private float GetAcceleratedAbsProgress() const
	{
		return Math::Saturate(Math::Abs(AcceleratedProgress.Value));
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		bInteractionStarted = true;
		if (Player.IsMio() && MioPlayerLocoFeature != nullptr)
		{
			bMioRequestAnim = true;
			Player.AddLocomotionFeature(MioPlayerLocoFeature, this, 50000);
		}
		else if (Player.IsZoe() && ZoePlayerLocoFeature != nullptr)
		{
			bZoeRequestAnim = true;
			Player.AddLocomotionFeature(ZoePlayerLocoFeature, this, 50000);
		}

		bInteracting[Player] = true;

		Player.AttachToComponent(InteractionComponent, NAME_None, EAttachmentRule::KeepWorld);

		if (bInteracting[Game::Zoe] && bInteracting[Game::Mio])
			StartButtonMash(Player);

		Player.ApplyCameraSettings(CamSettings, 0.5, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		if(bBothInteracting)
		{
			USanctuaryHydraKillerBallistaEventHandler::Trigger_OnStopDoubleInteraction(this);
			OnCanceled.Broadcast();
		}

		if (Player.IsMio() && MioPlayerLocoFeature != nullptr)
		{
			if (bInteractionCompleted)
				Timer::SetTimer(this, n"RemoveMioInteractAnim", 1.0);
			else
				RemoveMioInteractAnim();
		}
		else if (Player.IsZoe() && ZoePlayerLocoFeature != nullptr)
		{
			if (bInteractionCompleted)
				Timer::SetTimer(this, n"RemoveZoeInteractAnim", 1.0);
			else
				RemoveZoeInteractAnim();
		}

		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		for (auto MashPlayer : Game::GetPlayers())
			MashPlayer.StopButtonMash(this);

		bInteracting[Player] = false;

		Player.ClearCameraSettingsByInstigator(this, 0.5);

		bBothInteracting = false;
		TotalProgress = 0.0;
	}
	
	UFUNCTION()
	private void RemoveMioInteractAnim()
	{
		Game::Mio.RemoveLocomotionFeature(MioPlayerLocoFeature, this);
		bMioRequestAnim = false;
	}

	UFUNCTION()
	private void RemoveZoeInteractAnim()
	{
		Game::Zoe.RemoveLocomotionFeature(ZoePlayerLocoFeature, this);
		bZoeRequestAnim = false;
	}

	private void StartButtonMash(AHazePlayerCharacter LastInteractingPlayer)
	{
		for (auto Player : Game::GetPlayers())
		{
			Player.StartButtonMash(MashSettings, this);
			
			MashComp[Player] = UButtonMashComponent::Get(Player);
			MashComp[Player].SetAllowButtonMashCompletion(this, false);	
		}

		if (bInfuseArrow)
		{
			MioInteractComp.bPlayerCanCancelInteraction = false;
			ZoeInteractComp.bPlayerCanCancelInteraction = false;
			Timer::SetTimer(this, n"DelayedInfuse", 0.5);
		}

		bBothInteracting = true;
		OnBothPlayersInteracting.Broadcast(LastInteractingPlayer);

		USanctuaryHydraKillerBallistaEventHandler::Trigger_OnStartDoubleInteraction(this);
	}

	UFUNCTION()
	private void DelayedInfuse()
	{	
		ProjectileActor.Infuse();
	}

	UFUNCTION(NetFunction)
	private void NetInteractionCompleted()
	{
		bInteractionCompleted = true;
		bBothInteracting = false;
		ZoeInteractComp.KickAnyPlayerOutOfInteraction();
		ZoeInteractComp.Disable(this);
		MioInteractComp.KickAnyPlayerOutOfInteraction();
		MioInteractComp.Disable(this);

		PrepareLaunchTimeLike.PlayFromStart();

		if (bInfuseArrow)
		{
			ProjectileActor.Infuse();
		}

		OnMashCompleted.Broadcast();

		Timer::SetTimer(this, n"DelayedStartSplineRun", 6.0);
		USanctuaryHydraKillerBallistaEventHandler::Trigger_OnButtonMashCompleted(this);
	}

	UFUNCTION()
	private void DelayedStartSplineRun()
	{
		StopSplineRunComp.bShouldStop = false;
	}

	UFUNCTION()
	private void PrepareLaunchTimeLikeUpdate(float CurrentValue)
	{
		LauncherRootComp.SetRelativeLocation(FVector(-600.0 * GetAcceleratedAbsProgress(), 0.0, CurrentValue * -30.0));
	}

	UFUNCTION()
	private void PrepareLaunchTimeLikeFinished()
	{
		Timer::SetTimer(this, n"Fire", bInfuseArrow ? InfuseFireDelay : FireDelay);
	}

	UFUNCTION()
	private void Fire()
	{
		bFired = true;
		ProjectileActor.AttachToComponent(LauncherRootComp, NAME_None, EAttachmentRule::KeepWorld);
		PitchRotateComp.ApplyImpulse(PitchRotateComp.WorldLocation + PitchRotateComp.ForwardVector * 100.0, FVector::UpVector * 100.0);

		BP_Fire();
		USanctuaryHydraKillerBallistaEventHandler::Trigger_OnFire(this);

		ImpulseTimeLike.Play();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Fire(){}

	UFUNCTION()
	private void ImpulseTimeLikeUpdate(float CurrentValue)
	{
		FVector NewImpulseLocation = (FVector::ForwardVector * CurrentValue * -ImpulseDistance) + FVector::ForwardVector * 200.0;
		ImpulseRoot.SetRelativeLocation(NewImpulseLocation);
	}

	UFUNCTION()
	private void ImpulseTimeLikeFinished()
	{
		if (bInfuseArrow)
		{
			SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	void Break()
	{
		MioInteractComp.KickAnyPlayerOutOfInteraction();
		ZoeInteractComp.KickAnyPlayerOutOfInteraction();

		MioInteractComp.Disable(this);
		ZoeInteractComp.Disable(this);

		BP_Break();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Break(){}
};