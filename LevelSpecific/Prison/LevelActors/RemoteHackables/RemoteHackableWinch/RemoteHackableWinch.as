event void FRemoteHackableWinchListeners();

namespace Prison::RemoteHackableWinch
{
	const float HorizontalMaxSpeed = 800;
	const float HorizontalDrag = 1.8;

	const float VerticalMaxSpeed = 600;
	const float MinHeight = -19575.0;
};

class ARemoteHackableWinch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WinchRoot;
	
	UPROPERTY(DefaultComponent, Attach = WinchRoot)
	USceneComponent HookRoot;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	USpotLightComponent BottomShadowSpotlightComp;
	default BottomShadowSpotlightComp.SetIntensity(0.0);

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	USceneComponent BotRoot;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent) 
	URemoteHackingResponseAudioComponent HackingAudioComp;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	USceneComponent HangRoot;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FRemoteHackableWinchListeners OnHackingStarted;

	UPROPERTY()
	FRemoteHackableWinchListeners OnAttachPlayer;

	UPROPERTY()
	FRemoteHackableWinchListeners OnButtonPushed;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableWinchCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.InitialStoppedPlayerCapabilities.Add(n"RemoteHackableWinchHookCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncedActorPosition.SyncRate = EHazeCrumbSyncRate::Low;
	default SyncedActorPosition.SleepAfterIdleTime = 30.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedCurrentHeight;
	default SyncedCurrentHeight.DefaultValue = -200;
	default SyncedCurrentHeight.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedCurrentHeight.SleepAfterIdleTime = 30.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedHeightVelocity;
	default SyncedHeightVelocity.DefaultValue = 0.0;
	default SyncedHeightVelocity.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedHeightVelocity.SleepAfterIdleTime = 30.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedHeightInput;
	default SyncedHeightInput.DefaultValue = 0.0;
	default SyncedHeightInput.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedHeightInput.SleepAfterIdleTime = 30.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(EditAnywhere)
	float MoveForce = 1200.0;
	
	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBase LocomotionFeatureBotHanging;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset HangingPlayerCamSettings;

	float DefaultHeight;
	bool bHangingPlayerDead = false;
	FVector BotLoc;

	float MaxHeight = -300.0;

	UPROPERTY(EditInstanceOnly)
	AActor ButtonPushRefActor;
	bool bButtonPushed = false;
	bool bButtonReached = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PushButtonAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultHeight = ActorLocation.Z;

		SetActorControlSide(Game::Zoe);
		
		SyncedCurrentHeight.OverrideControlSide(Game::Mio);
		SyncedHeightVelocity.OverrideControlSide(Game::Mio);
		SyncedHeightInput.OverrideControlSide(Game::Mio);

		HackingComp.OnHackingStarted.AddUFunction(this, n"HackingStarted");
		HackingComp.OnHackingStopped.AddUFunction(this, n"HackingStopped");

		BotLoc = BotRoot.WorldLocation;

		SyncedCurrentHeight.SetValue(MaxHeight);

		MoveComp.SetupShapeComponent(CapsuleComp);
	}

	UFUNCTION()
	void UpdateMaxHeight(float NewHeight)
	{
		MaxHeight = NewHeight;
	}

	UFUNCTION()
	private void HackingStarted()
	{
		SetActorHiddenInGame(false);

		OnHackingStarted.Broadcast();
	}

	UFUNCTION()
	private void HackingStopped()
	{
		CapabilityRequestComp.StopInitialSheetsAndCapabilities(Game::Zoe, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bButtonPushed)
		{
			FVector AlignLoc = ButtonPushRefActor.ActorLocation;
			AlignLoc += (ButtonPushRefActor.ActorForwardVector * 15.0) + (FVector::DownVector * 25.0);
			FVector HookLoc = Math::VInterpTo(HookRoot.WorldLocation, AlignLoc, DeltaTime, 2.0);
			HookRoot.SetWorldLocation(HookLoc);

			if (!bButtonReached && HookLoc.Equals(AlignLoc, 5.0))
			{
				bButtonReached = true;
				Game::Zoe.StopBlendSpace();
				Game::Zoe.PlaySlotAnimation(Animation = PushButtonAnim);
				OnButtonPushed.Broadcast();
			}
		
			return;
		}

		if (HasVerticalControl())
		{
			HookRoot.SetRelativeLocation(FVector(0.0, 0.0, SyncedCurrentHeight.Value));
		}
		else
		{
			float LatestPosition = 0.0;
			float LatestCrumbTime = 0.0;
			SyncedCurrentHeight.GetLatestAvailableData(LatestPosition, LatestCrumbTime);

			float LatestVelocity = 0.0;
			float LatestVelocityTime = 0.0;
			SyncedHeightVelocity.GetLatestAvailableData(LatestVelocity, LatestVelocityTime);

			// Predict ahead by how far in the predicted past our latest data is
			// NOTE: We predict *more* into the future, because the FInterpTo later on is going to cause delay!
			float PredictTime = (Time::OtherSideCrumbTrailSendTimePrediction - LatestCrumbTime) + 0.3;

			LatestPosition += LatestVelocity * PredictTime;

			float PreviousPosition = HookRoot.RelativeLocation.Z;
			LatestPosition = Math::FInterpTo(PreviousPosition, LatestPosition, DeltaTime, 3.0);

			LatestPosition = Math::Clamp(LatestPosition, Prison::RemoteHackableWinch::MinHeight, MaxHeight);

			HookRoot.SetRelativeLocation(FVector(0.0, 0.0, LatestPosition));
		}

		FVector TargetBotLoc = HookRoot.WorldLocation;
		BotLoc = Math::VInterpTo(BotLoc, TargetBotLoc, DeltaTime, 8.0);
		BotLoc.Z = HookRoot.WorldLocation.Z + 300.0;
		BotRoot.SetWorldLocation(BotLoc);

		FVector DirToBot = (BotRoot.WorldLocation - HookRoot.WorldLocation).GetSafeNormal();
		FRotator BotRot = FRotator::MakeFromZY(DirToBot, ActorRightVector);
		BotRoot.SetWorldRotation(BotRot);
	}

	UFUNCTION()
	void AttachPlayer()
	{
		URemoteHackableWinchPlayerComponent PlayerComp = URemoteHackableWinchPlayerComponent::GetOrCreate(Game::Zoe);
		PlayerComp.WinchActor = this;
		CapabilityRequestComp.StartInitialSheetsAndCapabilities(Game::Zoe, this);

		OnAttachPlayer.Broadcast();
	}

	UFUNCTION()
	void UpdateCurrentHeight(float NewHeight)
	{
		SyncedCurrentHeight.SetValue(NewHeight);
		SyncedHeightVelocity.SetValue(0);

		SyncedCurrentHeight.TransitionSync(this);
		SyncedHeightVelocity.TransitionSync(this);

		HookRoot.SetRelativeLocation(FVector(0.0, 0.0, NewHeight));
	}

	UFUNCTION(BlueprintPure)
	FVector GetWinchInput() const
	{
		FVector WinchVelocity = SyncedActorPosition.GetPosition().MovementInput.GetSafeNormal();
		WinchVelocity.Z = SyncedHeightInput.Value;
		return WinchVelocity;
	}

	bool HasHorizontalControl() const
	{
		return HasControl();
	}

	bool HasVerticalControl() const
	{
		return SyncedCurrentHeight.HasControl();
	}

	UFUNCTION()
	void PushBottomButton()
	{
		bButtonPushed = true;
	}
}