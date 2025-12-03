event void FOnSolarFlareDoubleSwingStarted();
event void FOnSolarFlareDoubleSwingFinished();

class ASolarFlareDoubleSwingWeight : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareDoubleSwingStarted OnSolarFlareDoubleSwingStarted;

	UPROPERTY()
	FOnSolarFlareDoubleSwingFinished OnSolarFlareDoubleSwingFinished;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ContainerRoot;

	UPROPERTY(DefaultComponent, Attach = ContainerRoot)
	USceneComponent BreakRoot;

	UPROPERTY(DefaultComponent, Attach = BreakRoot)
	UStaticMeshComponent ContainerMeshComp;

	UPROPERTY(DefaultComponent, Attach = BreakRoot)
	UNiagaraComponent SparkEffectSolarSide;
	default SparkEffectSolarSide.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = BreakRoot)
	UNiagaraComponent SparkEffectPlayerSide;
	default SparkEffectPlayerSide.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftSwingIndicator;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightSwingIndicator;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;
	default SplineMoveComp.StartingDirection = -1;
	default SplineMoveComp.bBackAndForth = false;
	default SplineMoveComp.Speed = 2150.0;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent FlareReactComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlueLight;
	UMaterialInterface DefaultLight;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ContainerRotation;
	default ContainerRotation.AddDefaultKey(0.0, 0.0);
	default ContainerRotation.AddDefaultKey(0.5, 10.0);
	default ContainerRotation.AddDefaultKey(1.0, 30.0);
	default ContainerRotation.AddDefaultKey(2.25, 30.0);
	default ContainerRotation.AddDefaultKey(4.0, 45.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ContainerRotation2;
	default ContainerRotation2.AddDefaultKey(0.0, 0.0);
	default ContainerRotation2.AddDefaultKey(1.0, 20.0);
	default ContainerRotation2.AddDefaultKey(3.5, 20.0);
	default ContainerRotation2.AddDefaultKey(5.0, 35.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ContainerMoveSpeedCurve;
	default ContainerMoveSpeedCurve.AddDefaultKey(0.0, 0.0);
	default ContainerMoveSpeedCurve.AddDefaultKey(0.25, 20.0);
	default ContainerMoveSpeedCurve.AddDefaultKey(0.4, 0.0);
	default ContainerMoveSpeedCurve.AddDefaultKey(0.9, 0.0);
	default ContainerMoveSpeedCurve.AddDefaultKey(2.2, 400.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SparkActivationCurve;
	default SparkActivationCurve.AddDefaultKey(0.0, 0.0);
	default SparkActivationCurve.AddDefaultKey(4.0, 0.0);

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSetting;

	UPROPERTY(EditAnywhere)
	ASwingPoint Swing1;

	UPROPERTY(EditAnywhere)
	ASwingPoint Swing2;

	UPROPERTY(EditAnywhere)
	bool bContainerShouldBreak = true;

	bool bStartedMoving;

	TPerPlayer<bool> bPlayerAttached;

	bool bBeginDestruction;
	float BreakDuration;

	bool bTurnPlayerSideEffectOn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultLight = LeftSwingIndicator.GetMaterial(0);

		Swing1.OnPlayerAttachedToSwingPointEvent.AddUFunction(this, n"OnPlayerAttachedToSwingPointEvent");
		Swing2.OnPlayerAttachedToSwingPointEvent.AddUFunction(this, n"OnPlayerAttachedToSwingPointEvent");
		Swing1.OnPlayerDetachedFromSwingPointEvent.AddUFunction(this, n"OnPlayerDetachedFromSwingPointEvent");
		Swing2.OnPlayerDetachedFromSwingPointEvent.AddUFunction(this, n"OnPlayerDetachedFromSwingPointEvent");

		SplineMoveComp.OnSolarFlareSplineMoveCompReachedEnd.AddUFunction(this, n"OnSolarFlareSplineMoveCompReachedEnd");
		SplineMoveComp.OnSolarFlareSplineMoveCompReachedStart.AddUFunction(this, n"OnSolarFlareSplineMoveCompReachedStart");

		FlareReactComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SplineMoveComp.SplinePos.CurrentSplineDistance == SplineMoveComp.SplineComp.SplineLength && bStartedMoving)
		{
			bStartedMoving = false;
			OnSolarFlareDoubleSwingFinished.Broadcast();
		}

		if (bBeginDestruction && bContainerShouldBreak)
		{	
			BreakDuration += DeltaSeconds;
			BreakDuration = Math::Clamp(BreakDuration, 0.0, 5.0);
			BreakRoot.RelativeRotation = FRotator(ContainerRotation.GetFloatValue(BreakDuration), BreakRoot.RelativeRotation.Yaw, -ContainerRotation2.GetFloatValue(BreakDuration));
			BreakRoot.RelativeLocation -= FVector::UpVector * ContainerMoveSpeedCurve.GetFloatValue(BreakDuration) * DeltaSeconds;  
			
			if (!bTurnPlayerSideEffectOn && SparkActivationCurve.GetFloatValue(BreakDuration) > 0.9)
			{
				bTurnPlayerSideEffectOn = true;
				SparkEffectPlayerSide.Activate();
			}
			else if (bTurnPlayerSideEffectOn && SparkActivationCurve.GetFloatValue(BreakDuration) < 0.9)
			{
				bTurnPlayerSideEffectOn = false;
				SparkEffectPlayerSide.Deactivate();
			}
		}
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		if (bStartedMoving)
		{
			bBeginDestruction = true;
			SparkEffectSolarSide.Activate();
			SparkEffectPlayerSide.Activate();
			bTurnPlayerSideEffectOn = true;
			Timer::SetTimer(this, n"TimedDeactivateForSolarSide", 0.5, false);
			USolarFlareDoubleSwingWeightEffectHandler::Trigger_OnSolarFlareContainerStartBreak(this);
		}
	}

	UFUNCTION()
	void TimedDeactivateForSolarSide()
	{
		SparkEffectSolarSide.Deactivate();
	}	
	
	UFUNCTION(CallInEditor)
	void SetInitialLocation()
	{
		SplineMoveComp.SetInitialLocation();
	}

	UFUNCTION()
	private void OnPlayerAttachedToSwingPointEvent(AHazePlayerCharacter Player,
	                                               USwingPointComponent SwingPoint)
	{
		if (SwingPoint.Owner == Swing1)
			RightSwingIndicator.SetMaterial(0, BlueLight);
		else
			LeftSwingIndicator.SetMaterial(0, BlueLight);

		bPlayerAttached[Player] = true;
		Player.ApplyCameraSettings(CameraSetting, 2.5, this);

		FSolarFlareDoubleSwingWeightAttachParams AttachParams;
		AttachParams.Player = Player;
		USolarFlareDoubleSwingWeightEffectHandler::Trigger_OnSolarFlareDoubleSwingPlayerAttach(this, AttachParams);

		Player.BlockCapabilities(PlayerSwingTags::SwingJump, n"WaitForHandshake");
		Player.BlockCapabilities(PlayerSwingTags::SwingCancel, n"WaitForHandshake");
		Player.BlockCapabilities(CapabilityTags::Death, n"WaitForHandshake");
		Player.BlockCapabilities(CapabilityTags::Collision, n"WaitForHandshake");

		if (!Player.HasControl() || !Network::IsGameNetworked())
		{
			if (bPlayerAttached[Game::Mio] && bPlayerAttached[Game::Zoe])
			{
				NetStartEvent(Player);
			}
			else
			{
				NetReleasePlayer(Player);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetReleasePlayer(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(PlayerSwingTags::SwingJump, n"WaitForHandshake");
		Player.UnblockCapabilities(PlayerSwingTags::SwingCancel, n"WaitForHandshake");
		Player.UnblockCapabilities(CapabilityTags::Death, n"WaitForHandshake");
		Player.UnblockCapabilities(CapabilityTags::Collision, n"WaitForHandshake");
	}

	UFUNCTION(NetFunction)
	void NetStartEvent(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(PlayerSwingTags::SwingJump, n"WaitForHandshake");
		Player.UnblockCapabilities(PlayerSwingTags::SwingCancel, n"WaitForHandshake");
		Player.UnblockCapabilities(CapabilityTags::Death, n"WaitForHandshake");
		Player.UnblockCapabilities(CapabilityTags::Collision, n"WaitForHandshake");

		if (bStartedMoving)
			return;

		SplineMoveComp.ChangeDirection(1);
		bStartedMoving = true;

		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
		{
			SpeedEffect::RequestSpeedEffect(CurrentPlayer, 0.5, this, EInstigatePriority::Normal, 0.8, bUsePlayerMovement = false);
			CurrentPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
			CurrentPlayer.BlockCapabilities(CapabilityTags::Respawn, this);
			CurrentPlayer.BlockCapabilities(PlayerSwingTags::SwingJump, this);
			CurrentPlayer.BlockCapabilities(PlayerSwingTags::SwingCancel, this);
			CurrentPlayer.BlockCapabilities(CapabilityTags::Death, this);
			CurrentPlayer.BlockCapabilities(CapabilityTags::Collision, this);
			UCameraSettings::GetSettings(CurrentPlayer).FOV.ApplyAsAdditive(10.0, this);
			CurrentPlayer.PlayForceFeedback(Rumble, false, false, this);
		}
		
		Timer::SetTimer(this, n"DelayedCameraShake", 0.25);
		
		FSolarFlareDoubleSwingWeightParams LocParams;
		LocParams.Location = ActorLocation;
		USolarFlareDoubleSwingWeightEffectHandler::Trigger_OnSolarFlareDoubleSwingStartMoving(this, LocParams);
		
		OnSolarFlareDoubleSwingStarted.Broadcast();
	}

	UFUNCTION()
	void DelayedCameraShake()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShake, this);
		}
	}

	UFUNCTION()
	private void OnPlayerDetachedFromSwingPointEvent(AHazePlayerCharacter Player,
	                                                 USwingPointComponent SwingPoint)
	{
		if (SwingPoint.Owner == Swing1)
			RightSwingIndicator.SetMaterial(0, DefaultLight);
		else
			LeftSwingIndicator.SetMaterial(0, DefaultLight);

		bPlayerAttached[Player] = false;
		Player.ClearCameraSettingsByInstigator(this, 1.5);
		FSolarFlareDoubleSwingWeightAttachParams AttachParams;
		AttachParams.Player = Player;
		USolarFlareDoubleSwingWeightEffectHandler::Trigger_OnSolarFlareDoubleSwingPlayerDettach(this, AttachParams);
	}
	

	UFUNCTION()
	private void OnSolarFlareSplineMoveCompReachedStart()
	{
		Swing1.SwingPointComp.Enable(this);
		Swing2.SwingPointComp.Enable(this);

		FSolarFlareDoubleSwingWeightParams Params;
		Params.Location = ActorLocation;
		USolarFlareDoubleSwingWeightEffectHandler::Trigger_OnSolarFlareDoubleSwingStopMoving(this, Params);
	}

	UFUNCTION()
	private void OnSolarFlareSplineMoveCompReachedEnd()
	{
		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
		{
			CurrentPlayer.ClearCameraSettingsByInstigator(this, 2.0);
			SpeedEffect::ClearSpeedEffect(CurrentPlayer, this);
			CurrentPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
			CurrentPlayer.UnblockCapabilities(PlayerSwingTags::SwingJump, this);
			CurrentPlayer.UnblockCapabilities(PlayerSwingTags::SwingCancel, this);
			CurrentPlayer.UnblockCapabilities(CapabilityTags::Respawn, this);
			CurrentPlayer.UnblockCapabilities(CapabilityTags::Death, this);
			CurrentPlayer.UnblockCapabilities(CapabilityTags::Collision, this);
			UCameraSettings::GetSettings(CurrentPlayer).FOV.Clear(this, 1.0);
			bPlayerAttached[CurrentPlayer] = false;
			CurrentPlayer.PlayForceFeedback(Rumble, false, false, this, 0.5);
		}

		Swing1.SwingPointComp.Disable(this);
		Swing2.SwingPointComp.Disable(this);

		FSolarFlareDoubleSwingWeightParams Params;
		Params.Location = ActorLocation;
		USolarFlareDoubleSwingWeightEffectHandler::Trigger_OnSolarFlareDoubleSwingStopMoving(this, Params);

		SplineMoveComp.ChangeDirection(-1);
	}
}