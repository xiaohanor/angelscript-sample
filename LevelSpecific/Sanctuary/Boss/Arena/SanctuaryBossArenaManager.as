
// this is supposed to replace all the previous setup stuff in the level BP
class ASanctuaryBossArenaManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor DefeatedHydraCutsceneCamera = nullptr;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor SidescrollingCamera = nullptr;

	UPROPERTY(EditAnywhere)
	float BlendOutSidescrollingCameraTime = 2.0;

	UPROPERTY(EditAnywhere)
	float BlendInSidescrollingCameraTime = 2.0;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor SwoopBackCameraMio = nullptr;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor SwoopBackCameraZoe= nullptr;

	UPROPERTY(EditAnywhere)
	float BlendOutSwoopbackCameraTime = 1.5;

	UPROPERTY(EditAnywhere)
	float BlendInSwoopbackCameraTime = 1.5;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor ToAttackDestinationCameraZoe = nullptr;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor ToAttackDestinationCameraMio = nullptr;

	UPROPERTY(EditAnywhere)
	float BlendOutToAttackDestinationCameraTime = 2.0;

	UPROPERTY(EditAnywhere)
	float BlendInToAttackDestinationCameraTime = 4.0;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor GeneralAviationCamera = nullptr;

	UPROPERTY(EditAnywhere)
	ASanctuaryCompanionAviationToAttackCameraFocusActor ToAttackFocusActorMio;

	UPROPERTY(EditAnywhere)
	ASanctuaryCompanionAviationToAttackCameraFocusActor ToAttackFocusActorZoe;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor InitAttackCamera = nullptr;

	UPROPERTY(EditAnywhere)
	float BlendOutInitAttackCameraTime = 1.0;

	UPROPERTY(EditAnywhere)
	float BlendInInitAttackCameraTime = 3.0;

	UPROPERTY(EditAnywhere)
	AHazeActor SidescrollingFocusActorMio;

	UPROPERTY(EditAnywhere)
	AHazeActor SidescrollingFocusActorZoe;

	UPROPERTY(EditAnywhere)
	float BlendOutAviationCameraTime = 2.0;

	UPROPERTY(EditAnywhere)
	float BlendInAviationCameraTime = 3.0;
	
	UPROPERTY(EditAnywhere)
	ARespawnPoint ZoeFirstSpawnPoint = nullptr;

	UPROPERTY(EditAnywhere)
	ARespawnPoint MioFirstSpawnPoint = nullptr;

	UPROPERTY(EditAnywhere)
	UPlayerHealthSettings HealthSettings;

	private AHazePlayerCharacter Mio;
	private AHazePlayerCharacter Zoe;

	UPROPERTY(EditAnywhere)
	APlayerSplineLockZone SidescrollingZone = nullptr;

	UPROPERTY(EditAnywhere)
	ASplineActor EntrySpline = nullptr;

	UPROPERTY(EditAnywhere)
	ASplineActor FlightSpline = nullptr;

	UPROPERTY(EditAnywhere)
	ASplineActor ExitSpline = nullptr;

	UPROPERTY(EditAnywhere)
	ASplineActor CameraExitSpline = nullptr;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor KillCameraOne;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor KillCameraTwo;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor KillCameraThree;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor KillCameraFour;

	UPROPERTY(EditAnywhere)
	UPlayerSkydiveSettings SkydiveSettings;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	bool bAppliedSettings = false;
	bool bIsInSideScroller = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnableSidescrollingCamera(Game::Mio, true);
		EnableSidescrollingCamera(Game::Zoe, true);
	}

	UFUNCTION()
	void Setup()
	{
		StartPhaseOne();
		OnDestroyed.AddUFunction(this, n"HandleDestroyed");
		// CreateToAttackFocusTargetActors();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (bIsInSideScroller)
		{
			Game::Mio.ClearGameplayPerspectiveMode(this);
			Game::Zoe.ClearGameplayPerspectiveMode(this);
			bIsInSideScroller = false;
		}

		RemoveSettings();
	}

	UFUNCTION()
	private void HandleDestroyed(AActor DestroyedActor)
	{
		RemoveSettings();
	}

	UFUNCTION()
	void RemoveSettings()
	{
		if (bAppliedSettings)
		{
			bAppliedSettings = false;
			Game::Mio.ClearSettingsByInstigator(this);
			Game::Zoe.ClearSettingsByInstigator(this);
		}
	}

	void CreateToAttackFocusTargetActors()
	{
		ToAttackFocusActorMio = SpawnActor(ASanctuaryCompanionAviationToAttackCameraFocusActor, FVector::ZeroVector, FRotator::ZeroRotator, n"ToAttackFocusActorMio", true);
		ToAttackFocusActorMio.NetController = EHazePlayer::Mio;
		ToAttackFocusActorMio.MakeNetworked(this, n"ToAttackFocusActorMio");
		ToAttackFocusActorMio.SetActorControlSide(Game::Mio);
		FinishSpawningActor(ToAttackFocusActorMio);

		ASplineFollowCameraActor MioToAttackCamera = Cast<ASplineFollowCameraActor>(ToAttackDestinationCameraMio);
		FHazeCameraWeightedFocusTargetInfo MioToAttackFocusData;
		MioToAttackFocusData.SetFocusToActor(ToAttackDestinationCameraMio);
		MioToAttackCamera.FocusTargetComponent.AddFocusTarget(MioToAttackFocusData, this, EHazeSelectPlayer::Mio);

		ToAttackFocusActorZoe = SpawnActor(ASanctuaryCompanionAviationToAttackCameraFocusActor, FVector::ZeroVector, FRotator::ZeroRotator, n"ToAttackFocusActorZoe", true);
		ToAttackFocusActorZoe.NetController = EHazePlayer::Zoe;
		ToAttackFocusActorZoe.MakeNetworked(this, n"ToAttackFocusActorZoe");
		ToAttackFocusActorZoe.SetActorControlSide(Game::Zoe);
		FinishSpawningActor(ToAttackFocusActorZoe);

		ASplineFollowCameraActor ZoeToAttackCamera = Cast<ASplineFollowCameraActor>(ToAttackDestinationCameraZoe);
		FHazeCameraWeightedFocusTargetInfo ZoeToAttackFocusData;
		ZoeToAttackFocusData.SetFocusToActor(ToAttackDestinationCameraZoe);
		ZoeToAttackCamera.FocusTargetComponent.AddFocusTarget(ZoeToAttackFocusData, this, EHazeSelectPlayer::Zoe);
	}

	UFUNCTION(BlueprintCallable)
	void StartPhaseOne()
	{
		check(SidescrollingCamera != nullptr, "No sidescrolling camera on ASanctuaryBossArenaManager!");
		Mio = Game::Mio;
		Zoe = Game::Zoe;

		for (auto Player : Game::Players)
		{
			Player.ActivateCamera(SidescrollingCamera, 0.0, this, EHazeCameraPriority::Minimum);
			Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		}

		bAppliedSettings = true;

		//For now we do this in lvl;BP instead (cuz this one goes little crazy)
		//Mio.ApplySettings(HealthSettings, this, EHazeSettingsPriority::Gameplay);
		//Zoe.ApplySettings(HealthSettings, this, EHazeSettingsPriority::Gameplay);


		
		Mio.TeleportToRespawnPoint(MioFirstSpawnPoint, this);
		Zoe.TeleportToRespawnPoint(ZoeFirstSpawnPoint, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (AviationDevToggles::Phase1::Phase1DrawArenaSlices.IsEnabled())
			DebugDrawArenaSlices();
#endif
	}

	private void DebugDrawArenaSlices()
	{
		const float AddedHeightStep = 500.0;
		const float Length = 20000.0;
		FVector StartLocation = ActorLocation;
		FVector ToRight = ActorRightVector * Length;
		FVector ToLeft = -ActorRightVector * Length;
		FVector ToForward = ActorForwardVector * Length;
		FVector ToBack = -ActorForwardVector * Length;
		FVector NorthEast = (ActorRightVector + ActorForwardVector).GetSafeNormal() * Length;
		FVector NorthWest = (ActorRightVector - ActorForwardVector).GetSafeNormal() * Length;
		FVector SouthEast = (-ActorRightVector + ActorForwardVector).GetSafeNormal() * Length;
		FVector SouthWest = (-ActorRightVector - ActorForwardVector).GetSafeNormal() * Length;
		for (int i = 0; i < 1; ++i)
		{
			StartLocation.Z += AddedHeightStep;
			Debug::DrawDebugLine(StartLocation, StartLocation + ToRight, ColorDebug::Ruby,10.0, 0.0, true);
			Debug::DrawDebugLine(StartLocation, StartLocation + ToForward, ColorDebug::Radioactive,10.0, 0.0, true);
			Debug::DrawDebugLine(StartLocation, StartLocation + ToLeft, ColorDebug::Magenta,10.0, 0.0, true);
			Debug::DrawDebugLine(StartLocation, StartLocation + ToBack, ColorDebug::Cerulean,10.0, 0.0, true);

			Debug::DrawDebugLine(StartLocation + SouthWest, StartLocation + NorthEast, ColorDebug::White,10.0, 0.0, true);
			Debug::DrawDebugLine(StartLocation + SouthEast, StartLocation + NorthWest, ColorDebug::White,10.0, 0.0, true);
		}
	}

	UFUNCTION()
	private void OnActivatedAviation(AHazePlayerCharacter AviatingPlayer)
	{
		//SidescrollingZone.DisableForPlayer(AviatingPlayer, this);
	}

	void EnableSidescrollingCamera(AHazePlayerCharacter Player, bool bEnabled)
	{
		if (SidescrollingCamera == nullptr || SidescrollingCamera.IsActorBeingDestroyed())
			return;

		bIsInSideScroller = bEnabled;

		if (bEnabled)
		{
			Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
			Player.ActivateCamera(SidescrollingCamera, BlendInSidescrollingCameraTime, this, EHazeCameraPriority::High);
		}
		else
		{
			Player.ClearGameplayPerspectiveMode(this);
			Player.DeactivateCamera(SidescrollingCamera, BlendOutSidescrollingCameraTime);
		}
	}

	void EnableSwoopbackCamera(AHazePlayerCharacter Player, bool bEnabled)
	{
		AHazeCameraActor SwoopBackCamera = Player.IsMio() ? SwoopBackCameraMio : SwoopBackCameraZoe;
		if (SwoopBackCamera == nullptr || SwoopBackCamera.IsActorBeingDestroyed())
			return;

		if (bEnabled)
			Player.ActivateCamera(SwoopBackCamera, BlendInSwoopbackCameraTime, this, EHazeCameraPriority::VeryHigh);
		else
			Player.DeactivateCamera(SwoopBackCamera, BlendOutSwoopbackCameraTime);
	}

	void EnableAviationCamera(AHazePlayerCharacter Player, bool bEnabled)
	{
		if (GeneralAviationCamera == nullptr || GeneralAviationCamera.IsActorBeingDestroyed())
			return;

		if (bEnabled)
			Player.ActivateCamera(GeneralAviationCamera, BlendInAviationCameraTime, this, EHazeCameraPriority::Low);
		else
			Player.DeactivateCamera(GeneralAviationCamera, BlendOutAviationCameraTime);
	}

	void EnableInitAttackCamera(AHazePlayerCharacter Player, bool bEnabled)
	{
		if (InitAttackCamera == nullptr || InitAttackCamera.IsActorBeingDestroyed())
			return;

		if (bEnabled)
			Player.ActivateCamera(InitAttackCamera, BlendInInitAttackCameraTime, this, EHazeCameraPriority::VeryHigh);
		else
			Player.DeactivateCamera(InitAttackCamera, BlendOutInitAttackCameraTime);
	}

	void EnableToAttackDestinationCamera(AHazePlayerCharacter Player, bool bEnabled)
	{
		AHazeCameraActor ToAttackDestinationCamera = Player.IsMio() ? ToAttackDestinationCameraMio : ToAttackDestinationCameraZoe;
		if (ToAttackDestinationCamera == nullptr || ToAttackDestinationCamera.IsActorBeingDestroyed())
			return;

		if (bEnabled)
			Player.ActivateCamera(ToAttackDestinationCamera, BlendInToAttackDestinationCameraTime, this, EHazeCameraPriority::High);
		else
			Player.DeactivateCamera(ToAttackDestinationCamera, BlendOutToAttackDestinationCameraTime);
	}

	UFUNCTION()
	private void OnDeactivatedAviation(AHazePlayerCharacter AviatingPlayer)
	{
		//SidescrollingZone.EnableForPlayer(AviatingPlayer, this);
	}
}