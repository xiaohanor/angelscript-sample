event void FOnMoonMarketPumpkinLauncherUsed();

class AMoonMarketPumpkinLauncher : AHazeActor
{
	UPROPERTY()
	FOnMoonMarketPumpkinLauncherUsed OnMoonMarketPumpkinLauncherUsed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent AppearEffect;
	default AppearEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UScenepointComponent AttachRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CamComp;

	UPROPERTY(EditInstanceOnly)
	AActor LandingLocation;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AnimSeq;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve RotateCurve;
	float YawRotate = 180.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SquishDownCurve;
	float ZScaleReude = 0.3;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ThickenCurve;
	float XYScaleAdd = 0.3;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve CameraCurve;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchRumble;

	AHazePlayerCharacter TargetPlayer;

	float AnimTime = 1.0;
	float ActiveDuration;
	float TotalLaunchDuration = 4.0;
	float PlayerlaunchTimeStamp = 2.1;

	bool bPumpkinActive;
	bool bPlayerLaunched;

	FVector StartScale;
	FRotator TargetRotation;
	FRotator StartRotation;

	FVector CamStartLocation;
	FRotator CamStartRotation;
	float OffsetForward = 250.0;
	float OffsetDownRot = -10.0;
	FHazeAcceleratedVector AccelCamLoc;
	FHazeAcceleratedRotator AccelCamRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CamStartLocation = CamComp.WorldLocation;
		CamStartRotation = CamComp.WorldRotation;
		AccelCamLoc.SnapTo(CamStartLocation);
		AccelCamRot.SnapTo(CamStartRotation);

		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		StartScale = MeshRoot.RelativeScale3D;

		if (!bStartActivated)
		{
			AddActorDisable(this);
		}

		FVector Direction = (LandingLocation.ActorLocation - MeshRoot.WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		TargetRotation = Direction.Rotation();
		StartRotation = MeshRoot.WorldRotation;
		CamComp.WorldRotation = TargetRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPumpkinActive)
		{
			ActiveDuration += DeltaSeconds;

			if (ActiveDuration > AnimTime)
			{
				float Duration = ActiveDuration - AnimTime;
				float YawAlpha = RotateCurve.GetFloatValue(Duration);
				float SquishDown = SquishDownCurve.GetFloatValue(Duration);
				float Thicken = ThickenCurve.GetFloatValue(Duration);
				MeshRoot.WorldRotation = FQuat::Slerp(StartRotation.Quaternion(), TargetRotation.Quaternion(), YawAlpha).Rotator();
				MeshRoot.RelativeScale3D = StartScale + FVector(0, 0, SquishDown);
				MeshRoot.RelativeScale3D += FVector(Thicken, Thicken, 0);

				float Alpha = Math::Saturate(Duration / PlayerlaunchTimeStamp);
				FVector LocationTarget = CamStartLocation + (CamComp.ForwardVector * CameraCurve.GetFloatValue(Alpha) * OffsetForward);
				FRotator RotationTarget = CamStartRotation + FRotator(CameraCurve.GetFloatValue(Alpha) * OffsetDownRot, 0, 0);
				AccelCamLoc.AccelerateTo(LocationTarget, 0.5, DeltaSeconds);
				AccelCamRot.AccelerateTo(RotationTarget, 0.5, DeltaSeconds);
				CamComp.WorldLocation = AccelCamLoc.Value;
				CamComp.WorldRotation = AccelCamRot.Value;

				if (Duration > TotalLaunchDuration)
				{
					bPumpkinActive = false;
					InteractComp.Enable(this);
				}

				if (Duration > PlayerlaunchTimeStamp && !bPlayerLaunched)
				{
					bPlayerLaunched = true;
					
					TargetPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
					TargetPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
					TargetPlayer.UnblockCapabilities(CapabilityTags::Input, this);
					TargetPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);	
					TargetPlayer.PlayCameraShake(CameraShake, this);
					TargetPlayer.PlayForceFeedback(LaunchRumble, false, true, this);				
					
					FPlayerLaunchToParameters Params;
					Params.Duration = Duration;
					Params.LaunchToLocation = LandingLocation.ActorLocation;
					Params.Type = EPlayerLaunchToType::LaunchToPoint;
					
					TargetPlayer.LaunchPlayerTo(this, Params);
					TargetPlayer.DeactivateCameraByInstigator(this, 0.5);

					OnMoonMarketPumpkinLauncherUsed.Broadcast();
				}
			}
		}
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		AccelCamLoc.SnapTo(CamStartLocation);
		AccelCamRot.SnapTo(CamStartRotation);
		CamComp.WorldLocation = AccelCamLoc.Value;
		CamComp.WorldRotation = AccelCamRot.Value;
		
		ActiveDuration = 0;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.AttachToComponent(AttachRoot, NAME_None, EAttachmentRule::KeepWorld);
		Player.SmoothTeleportActor(AttachRoot.WorldLocation, AttachRoot.WorldRotation, this, 0.5);
		InteractComp.Disable(this);
		bPumpkinActive = true;
		bPlayerLaunched = false;

		Player.ActivateCamera(CamComp, 3.0, this);
		TargetPlayer = Player;
	}

	void GraveyardPumpkinAppear()
	{
		RemoveActorDisable(this);
		AppearEffect.Activate();
	}
};