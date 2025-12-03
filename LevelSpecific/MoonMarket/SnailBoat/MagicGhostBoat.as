event void FOnMagicBoatStartMoving();
event void FOnMagicBoatFinishMoving();

class AMagicGhostBoat : AHazeActor
{
	UPROPERTY()
	FOnMagicBoatStartMoving OnMagicBoatStartMoving;

	UPROPERTY()
	FOnMagicBoatFinishMoving OnMagicBoatFinishMoving;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BobRoot;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	USceneComponent OarRoot1;

	UPROPERTY(DefaultComponent, Attach = OarRoot1)
	UStaticMeshComponent OarMesh1;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	USceneComponent OarRoot2;

	UPROPERTY(DefaultComponent, Attach = OarRoot2)
	UStaticMeshComponent OarMesh2;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMoonMarketFollowSplineComp FollowComp;
	default FollowComp.bStartActive = false;
	default FollowComp.Speed = 700.0;
	default FollowComp.SpeedChangePerSecond = 100.0;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<UAnimSequence> SitAnimations;

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<UAnimSequence> ExitAnimations;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsOnMove;

	UPROPERTY(EditInstanceOnly)
	ASplineFollowCameraActor SplineFollowCamera;

	UPROPERTY(EditInstanceOnly)
	AActor FocusTarget;

	UPROPERTY(EditInstanceOnly)
	AMagicGhostBoatCamera GhostBoatCamera;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor SittingCamera;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve OarCurveRoll;
	default OarCurveRoll.AddDefaultKey(0.0, 0.0);
	default OarCurveRoll.AddDefaultKey(0.25, 1.0);
	default OarCurveRoll.AddDefaultKey(0.75, -1.0);
	default OarCurveRoll.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve OarCurveYaw;
	default OarCurveYaw.AddDefaultKey(0.0, 0.0);
	default OarCurveYaw.AddDefaultKey(0.5, 1.0);
	default OarCurveYaw.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveToStartCurve;
	default MoveToStartCurve.AddDefaultKey(0.0, 0.0);
	default MoveToStartCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveToStartUpOffset;
	default MoveToStartUpOffset.AddDefaultKey(0.0, 0.0);
	default MoveToStartUpOffset.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect OarRumble;

	UPROPERTY(EditAnywhere)
	float MoveToStartDuration = 6.5;
	float CurrentMoveTime;

	UPROPERTY(EditAnywhere)
	ARespawnPointVolume RespawnVolume;

	// FVector StartLoc;
	FVector OffsetLoc;

	FRotator OarStartRot1;
	FRotator OarStartRot2;
	float YawRotateAmount = 110.0;
	float PitchRotateAmount = 90.0;
	float RotationDuration = 3.5;
	float Alpha;

	FHazeAcceleratedFloat AccelFloatRoll;
	FHazeAcceleratedFloat AccelFloatYaw;

	FVector TargetSplineStartLoc;
	FVector StartLocation;
	FVector UpOffset = FVector(0,0,1000.0);
	FVector BobOffset = FVector(0,0,20); 

	bool bRowing;
	bool bCanRow;
	bool bPlayedRowRumble;
	bool bCanMoveToStart;

	float TargetValue = 0.04;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FollowComp.OnFreakyReachedEndOfSpline.AddUFunction(this, n"OnFreakyReachedEndOfSpline");
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		DoubleInteract.OnPlayerStartedInteracting.AddUFunction(this, n"PlayerStartInteracting");
		DoubleInteract.OnPlayerStoppedInteracting.AddUFunction(this, n"OnPlayerStoppedInteracting");
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		DoubleInteract.AddActorDisable(this);

		OarStartRot1 = OarRoot1.RelativeRotation;
		OarStartRot2 = OarRoot2.RelativeRotation;

		TargetSplineStartLoc = FollowComp.Spline.GetWorldLocationAtSplineDistance(0);
		ActorLocation -= ActorForwardVector * 2500.0;
		StartLocation = ActorLocation;
		bCanRow = true;
		bRowing = true;

		MeshComp.SetScalarParameterValueOnMaterials(n"Opacity", 0.0);
		OarMesh1.SetScalarParameterValueOnMaterials(n"Opacity", 0.0);
		OarMesh2.SetScalarParameterValueOnMaterials(n"Opacity", 0.0);

		DoubleInteract.DisableDoubleInteraction(this);
		DoubleInteract.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

		RespawnVolume.DisableRespawnPointVolume(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float BobAlpha = Math::Sin(Time::GameTimeSeconds * 1.0);
		BobRoot.RelativeLocation = FVector(0,0,20) * BobAlpha;
		BobRoot.RelativeLocation += FVector(40,0,0) * BobAlpha * 0.25;

		if (bCanMoveToStart && !FollowComp.bFollowActive)
		{
			CurrentMoveTime += DeltaSeconds;
			float MoveAlpha = Math::Saturate(CurrentMoveTime / MoveToStartDuration);
			ActorLocation = Math::Lerp(StartLocation, TargetSplineStartLoc, MoveToStartCurve.GetFloatValue(MoveAlpha));
			FVector Offset = Math::Lerp(UpOffset, FVector(0), MoveToStartUpOffset.GetFloatValue(MoveAlpha));
			ActorLocation += Offset;
			MeshComp.SetScalarParameterValueOnMaterials(n"Opacity", TargetValue *  MoveToStartCurve.GetFloatValue(MoveAlpha));
			OarMesh1.SetScalarParameterValueOnMaterials(n"Opacity", TargetValue *  MoveToStartCurve.GetFloatValue(MoveAlpha));
			OarMesh2.SetScalarParameterValueOnMaterials(n"Opacity", TargetValue *  MoveToStartCurve.GetFloatValue(MoveAlpha));

			if (MoveAlpha == 1.0)
			{
				bCanRow = false;
				bRowing = false;
				bCanMoveToStart = false;
				DoubleInteract.EnableDoubleInteraction(this);
			}
		}

		if (bCanRow)
			Alpha += DeltaSeconds / RotationDuration; 

		float YawRot1 = OarCurveYaw.GetFloatValue(Alpha) * YawRotateAmount;
		float RollRot1 = OarCurveRoll.GetFloatValue(Alpha) * PitchRotateAmount;

		AccelFloatYaw.AccelerateTo(YawRot1, 1.5, DeltaSeconds);
		AccelFloatRoll.AccelerateTo(RollRot1, 1.5, DeltaSeconds);

		OarRoot1.RelativeRotation = FRotator(0.0, AccelFloatYaw.Value, AccelFloatRoll.Value);
		OarRoot2.RelativeRotation = FRotator(0.0, -AccelFloatYaw.Value, -AccelFloatRoll.Value);

		GhostBoatCamera.SetAlphaValue(FollowComp.GetFollowSplineAlphaProgress());
		
		if (!bPlayedRowRumble && Alpha > 0.5 && bCanRow && FollowComp.bFollowActive)
		{
			bPlayedRowRumble = true;
			for (AHazePlayerCharacter Player : Game::Players)
			{
				float Distance = (Player.ActorLocation - ActorLocation).Size();
				float Multiplier = Math::Saturate(500.0 / Distance);
				if (Multiplier > 0.6)
					Multiplier = 1.0;
				else if (Multiplier < 0.1)
					Multiplier = 0.0;

				Player.PlayForceFeedback(OarRumble, false, false, this, 0.1 * Multiplier);
			}
		}

		if (Alpha > 1.0)
		{
			float Remainder = Alpha - 1.0;
			Alpha = Remainder;
			bPlayedRowRumble = false;

			if (!bRowing)
			{
				bCanRow = false;
			}
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		bCanMoveToStart = true;
		DoubleInteract.RemoveActorDisable(this);
		UMagicGhostBoatEventHandler::Trigger_OnBoatAppear(this);
	}

	UFUNCTION()
	private void PlayerStartInteracting(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                                    UInteractionComponent InteractionComponent)
	{
		// Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimSit, true, BlendTime = 0.75);
		UMagicGhostBoatSitComponent::GetOrCreate(Player).Sit(this, InteractionComponent);

		Player.ActivateCamera(SittingCamera, 4.0, this);
	}

	UFUNCTION()
	private void OnPlayerStoppedInteracting(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		if (bRowing)
			return;
		
		UMagicGhostBoatSitComponent::GetOrCreate(Player).StopSitting();
		Player.DeactivateCameraByInstigator(this, 1);
		// Player.StopAllSlotAnimations(0.5);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), SitAnimations[Player], true, BlendTime = 0.75);
			Player.ActivateCamera(GhostBoatCamera, 3.0, this);
			Player.ApplyCameraSettings(CameraSettingsOnMove, 8.0, this);
		}
		
		bRowing = true;
		bCanRow = true;

		DoubleInteract.AddActorDisable(this);

		FollowComp.ActivateSplineFollow();

		GhostBoatCamera.StartBackOffsetBlend();
		Timer::SetTimer(this, n"BlendToFullScreen", 1.0);

		RespawnVolume.EnableRespawnPointVolume(this);

		UMagicGhostBoatEventHandler::Trigger_OnBoatStartedRide(this);
		OnMagicBoatStartMoving.Broadcast();
	}

	UFUNCTION()
	void BlendToFullScreen()
	{
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::AcceleratedSlow);
	}


	UFUNCTION()
	private void OnFreakyReachedEndOfSpline()
	{
		bRowing = false;
		UMagicGhostBoatEventHandler::Trigger_OnBoatFinishedRide(this);
		Timer::SetTimer(this, n"DelayedLeaveBoat", 1.0, false);

		OnMagicBoatFinishMoving.Broadcast();
	}

	UFUNCTION()
	void DelayedLeaveBoat()
	{
		Camera::BlendToSplitScreenUsingProjectionOffset(this, 4.5);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UMagicGhostBoatSitComponent::Get(Player).StopSitting();
			Player.ClearCameraSettingsByInstigator(this, 5.0);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			FTransform PlayerTransform = Player.Mesh.GetBoneTransform(n"Base");
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), ExitAnimations[Player], false, BlendTime = 0.75);
			// Player.DeactivateCamera(GhostBoatCamera, 3.5);
			Player.DeactivateCameraByInstigator(this, 3.5);
			
			Timer::SetTimer(this, n"DelayUnblock", 2.6);
		}
	}

	UFUNCTION()
	void DelayUnblock()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.DetachFromActor(EDetachmentRule::KeepWorld);
		}
	}

	UFUNCTION()
	void SetEndState()
	{
		MeshComp.SetScalarParameterValueOnMaterials(n"Opacity", TargetValue *  MoveToStartCurve.GetFloatValue(1.0));
		OarMesh1.SetScalarParameterValueOnMaterials(n"Opacity", TargetValue *  MoveToStartCurve.GetFloatValue(1.0));
		OarMesh2.SetScalarParameterValueOnMaterials(n"Opacity", TargetValue *  MoveToStartCurve.GetFloatValue(1.0));

		DoubleInteract.DisableDoubleInteraction(this);

		FTransform FinalTransform = FollowComp.Spline.GetWorldTransformAtSplineDistance(FollowComp.Spline.SplineLength);
		ActorLocation = FinalTransform.Location;
		ActorRotation = FinalTransform.Rotator();

		RespawnVolume.EnableRespawnPointVolume(this);

		bCanRow = false;
		bRowing = false;
	}
};