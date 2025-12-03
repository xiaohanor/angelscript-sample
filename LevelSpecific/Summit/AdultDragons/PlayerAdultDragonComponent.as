enum EAdultDragonAnimationState
{
	Hover,
	Flying,
	Dash
};

enum EAdultDragonStormState
{
	Default,
	StormLoop
}

enum EAdultDragonFlightMode
{
	NotSet UMETA(Hidden),
	NotStarted,
	Flying,
	Strafing,
	CircleStrafing,
	FreeFlying,
	Stopped
}

struct FAdultDragonAnimationParams
{
	FRotator SplineRelativeDragonRotation;

	float Banking;
	float Pitching;

	bool bIsShooting = false;
	// Set for first frame of dashing
	bool bDashInitialized = false;

	bool bIsSwimming = false;

	float AnimationFlyingTurnAmount = 0.0;
	float AnimationFlyingForwardAmount = 1.0;
	FHazeAcceleratedFloat AnimAirSmashRoll;

	void PrintValues()
	{
		Print(f"{Banking=}", 0);
		Print(f"{Pitching=}", 0);
		Print(f"{bIsShooting=}", 0);
		Print(f"{bDashInitialized=}", 0);
		Print(f"{bIsSwimming=}", 0);
		Print(f"{AnimationFlyingTurnAmount=}", 0);
		Print(f"{AnimationFlyingForwardAmount=}", 0);
		Print(f"{AnimAirSmashRoll.Value=}", 0);
	}
}

UCLASS(Abstract)
class UPlayerAdultDragonComponent : UActorComponent
{
	access ProtectedReadOnly = protected, *(readonly);

	UPROPERTY(Category = "Setup")
	TSubclassOf<AAdultDragon> AdultDragonClass;

	UPROPERTY(Category = "Setup")
	FName PlayerAttachSocket = n"Spine4";

	UPROPERTY(Category = "Setup")
	FVector AttachmentOffset;

	UPROPERTY(Category = "Setup")
	TMap<EAdultDragonFlightMode, UHazeCapabilitySheet> FlightModeSheets;

	UPROPERTY(Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Settings")
	TMap<EDragonGapFlyingCameraSettingsType, UHazeCameraSettingsDataAsset> DefaultGapSideFlyingSettingsAssets;

	UHazeCameraSettingsDataAsset SideFlyingCameraSettings;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UCameraShakeBase> ClosingGapCameraShake;

	UPROPERTY(Category = "Settings")
	UAdultDragonFlightSettings ChaseSettings;

	/*
	Camera settings which gets enabled at the start before you start flying
	Starts immediately when you start without flying and zooms out slowly to show scale
	*/
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset StartCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> ConstantShake;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect DashRumble;

	UPROPERTY(Category = "DeathSettings")
	TSubclassOf<UDeathEffect> ImpactDeathEffect;

	UPROPERTY(Category = "DeathSettings")
	TSubclassOf<UDamageEffect> ImpactDamageEffect;

	bool bIsBeingBoundaryRedirected = false;

	FAdultDragonAnimationParams AnimParams;
	TInstigated<EAdultDragonAnimationState> AnimationState;

	// CAMERA LAG
	bool bCameraShouldLagBehind = false;
	float CameraLagDuration = 0.5;
	float TimeOfStartCameraLag = -100.0;
	FVector DragonPosWhenStartCameraLag;

	bool bGapFlying;
	bool bIsUsingGapFlyMovement;
	bool bNewGapFlyingDataSet;
	bool bCanInputRotate = true;
	bool bIsDashing = false;
	
	float TimeStoppedGapFlying = 0;

	FVector DashVelocity;

	TOptional<FDragonGapFlyingData> GapFlyingData;
	TArray<FInstigator> AimingInstigators;

	// Storm Strafe
	EAdultDragonStormState StormState;

	// DEV INPUT TOGGLES
	bool bRightStickCameraIsOn = false;

	// FLIGHT MODE
	EAdultDragonFlightMode FlightMode = EAdultDragonFlightMode::NotSet;

	UHazeCapabilitySheet CurrentlyActiveSheet = nullptr;

	float Speed;
	TMap<UObject, float> BonusSpeed;
	FHazeAcceleratedRotator AccRotation;
	FRotator WantedRotation;
	FHazeAcceleratedFloat RotationAccelerationDuration;

	bool bIsTwirling;
	float TwirlDuration;
	int NrOfTwirlSpins;

	TInstigated<FRotator> DesiredCameraRotation;

	// OBS! Do NOT expose these.
	// The dragon is just a "dead" actor attached to the player
	// The player IS the dragon, moving and having all the capabilities
	access:ProtectedReadOnly AAdultDragon AdultDragon;
	access:ProtectedReadOnly AHazePlayerCharacter PlayerOwner;

	UFUNCTION()
	void ToggleFreeFly()
	{
		Console::ExecuteConsoleCommand("Summit.ToggleFreefly");
	}
	
	UPROPERTY(EditAnywhere)
	float WingFlappingStrength = 1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Velocity = PlayerOwner.GetActorVelocity().Size();
		DragonMesh.SetScalarParameterValueOnMaterials(n"wingFlappingStrength", Math::Clamp((Velocity / 200) * WingFlappingStrength, 0, 150));

#if EDITOR
		auto TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("FlightMode", FlightMode)
			.Value("WingFlappingStrength", WingFlappingStrength)
			.Value("Speed", Speed)
			.Value("bCanInputRotate", bCanInputRotate)
			.Value("AccRotation", AccRotation.Value)
			.Value("WantedRotation", WantedRotation)
			.Value("Camera;CameraLagDuration", CameraLagDuration)
			.Value("Camera;bCameraShouldLagBehind", bCameraShouldLagBehind)
			.Value("Camera;TimeOfStartCameraLag", TimeOfStartCameraLag)
			.Value("GapFlying;bGapFlying", bGapFlying)
			.Value("GapFlying;bNewGapFlyingDataSet", bNewGapFlyingDataSet);
#endif
	}

	float GetMovementSpeed() const
	{
		float Out = Speed;
		for (auto It : BonusSpeed)
		{
			Out += It.Value;
		}
		return Out;
	}

	float GetBonusMovementSpeed() const
	{
		float Out = 0;
		for (auto It : BonusSpeed)
		{
			Out += It.Value;
		}
		return Out;
	}

	UFUNCTION()
	void Twirl(float Duration, int NrOfSpins)
	{
		TwirlDuration = Duration;
		NrOfTwirlSpins = NrOfSpins;
		bIsTwirling = true;
	}

	void ApplyCameraLag(float Duration)
	{
		bCameraShouldLagBehind = true;
		CameraLagDuration = Duration;
		TimeOfStartCameraLag = Time::GetGameTimeSeconds();
		DragonPosWhenStartCameraLag = AdultDragon.ActorLocation;
	}

	UFUNCTION()
	void SetStormState(EAdultDragonStormState NewState)
	{
		StormState = NewState;
	}

	UFUNCTION(BlueprintCallable)
	void SetFlightMode(EAdultDragonFlightMode NewFlightMode)
	{
		if (FlightMode == NewFlightMode)
			return;

		if (CurrentlyActiveSheet != nullptr)
			PlayerOwner.StopCapabilitySheet(CurrentlyActiveSheet, this);

		if (NewFlightMode != EAdultDragonFlightMode::Stopped)
		{
			CurrentlyActiveSheet = FlightModeSheets[NewFlightMode];

			if (FlightMode == EAdultDragonFlightMode::Stopped)
				PlayerOwner.UnblockCapabilities(AdultDragonCapabilityTags::AdultDragon, this);

			PlayerOwner.StartCapabilitySheet(CurrentlyActiveSheet, this);
		}
		else
		{
			CurrentlyActiveSheet = nullptr;
			PlayerOwner.BlockCapabilities(AdultDragonCapabilityTags::AdultDragon, this);
		}
		FlightMode = NewFlightMode;
	}

	AAdultDragon SpawnDragon(AHazePlayerCharacter Player, TSubclassOf<AAdultDragon> DragonType)
	{
		PlayerOwner = Player;

		FHazeDevInputInfo ToggleInputInfo;
		ToggleInputInfo.Name = n"Toggle Freefly";
		ToggleInputInfo.Category = n"Dragon Flying";
		// ToggleInputInfo.DisplaySortOrder = 210;
		ToggleInputInfo.OnTriggered.BindUFunction(this, n"ToggleFreeFly");
		ToggleInputInfo.AddKey(EKeys::Gamepad_FaceButton_Right);
		ToggleInputInfo.AddKey(EKeys::G);

		PlayerOwner.RegisterDevInput(ToggleInputInfo);

		AdultDragon = SpawnActor(DragonType, bDeferredSpawn = true);
		AdultDragon.MakeNetworked(Player);
		AdultDragon.SetActorControlSide(Player);

		AdultDragon.SetControllingPlayer(Player);
		AdultDragon.CapsuleComponent.AddComponentCollisionBlocker(AdultDragon);
		FinishSpawningActor(AdultDragon);
		AdultDragon.AttachRootComponentTo(Player.RootComponent, NAME_None, EAttachLocation::SnapToTarget, true);

		UHazeSequenceRenderSingleton SequenceRenderSingleton = Game::GetSingleton(UHazeSequenceRenderSingleton);
		if (SequenceRenderSingleton != nullptr)
		{
			if (Player.Player == EHazePlayer::Mio)
				SequenceRenderSingleton.AdultDragonMio = AdultDragon;
			else
				SequenceRenderSingleton.AdultDragonZoe = AdultDragon;
		}

		return AdultDragon;
	}

	// Temp use for side flying prototype
	AAdultDragon GetAdultDragon() const
	{
		return AdultDragon;
	}

	void SetGapFlying(bool bNewGapFlying, FDragonGapFlyingData NewData, UHazeCameraSettingsDataAsset OverrideCamSettings = nullptr)
	{
		if (bGapFlying)
		{
			bNewGapFlyingDataSet = true;
		}

		bGapFlying = bNewGapFlying;
		if (bNewGapFlying)
		{
			GapFlyingData.Set(NewData);
			TimeStoppedGapFlying = MAX_flt;
		}
		else
		{
			GapFlyingData.Reset();
			TimeStoppedGapFlying = Time::GameTimeSeconds;
		}

		if (OverrideCamSettings != nullptr)
			SideFlyingCameraSettings = OverrideCamSettings;
		else if (GapFlyingData.IsSet())
			SideFlyingCameraSettings = DefaultGapSideFlyingSettingsAssets[GapFlyingData.Value.CameraSettingsType];
	}

	UHazeCharacterSkeletalMeshComponent GetDragonMesh() const property
	{
		return AdultDragon.Mesh;
	}

	void RequestLocomotionDragonAndPlayer(FName LocomotionTag)
	{
		if (PlayerOwner != nullptr && PlayerOwner.Mesh.CanRequestLocomotion())
		{
			// Player.Mesh.RequestLocomotion(LocomotionTag, this);
			PlayerOwner.Mesh.RequestLocomotion(n"DragonRiding", this);
		}

		if (AdultDragon.Mesh.CanRequestLocomotion())
		{
			AdultDragon.Mesh.RequestLocomotion(LocomotionTag, this);
		}
	}

	void AddDragonVisualsBlock(FInstigator Instigator)
	{
		AdultDragon.AddActorVisualsBlock(Instigator);
	}

	void RemoveDragonVisualsBlock(FInstigator Instigator)
	{
		AdultDragon.RemoveActorVisualsBlock(Instigator);
	}

	bool WantsAiming() const
	{
		return AimingInstigators.Num() > 0;
	}
};