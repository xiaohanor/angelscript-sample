asset PrisonStealthCameraSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPrisonStealthCameraIdleCapability);
	Capabilities.Add(UPrisonStealthCameraSearchCapability);
	Capabilities.Add(UPrisonStealthCameraStunnedCapability);

	Capabilities.Add(UPrisonStealthVisionCapability);
	Capabilities.Add(UPrisonStealthDetectionCapability);
	Capabilities.Add(UPrisonStealthShootPlayerCapability);
	Capabilities.Add(UPrisonStealthEnemyEventsCapability);
};

UCLASS(Abstract, HideCategories = "Collision Rendering Activation Cooking Actor")
class APrisonStealthCamera : APrisonStealthEnemy
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Grip;

    UPROPERTY(DefaultComponent, Attach = Grip)
	UStaticMeshComponent Camera;

    UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Camera)
	USpotLightComponent SpotLight;

	UPROPERTY(DefaultComponent, Attach = Camera)
	UPrisonStealthVisionComponent VisionComp;

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent TurretHitResponseComponent;

	UPROPERTY(DefaultComponent)
	UPrisonStealthStunnedComponent StunnedComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(PrisonStealthCameraSheet);

	// How smoothly to follow the rotation of a spline or swiveling look. Lower values means more loose, and higher is more snappy.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float RotationInterpSpeed = 5.0;

	// Frequency of the swiveling rotation when standing still.
	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float SwivelFrequency = 2.0;

	UPROPERTY(EditAnywhere, Category = "Patrolling")
	float SwivelAmount = 30.0;

	float TargetPitch = 0.0;

	/**
	 * Searching
	 */

	// How long (in seconds) should the camera stop and search for the player? This is time from the last time the player was spotted.
	UPROPERTY(EditAnywhere, Category = "Searching")
	float SearchTime = 3.0;

	UPROPERTY(EditAnywhere, Category = "Searching")
	float SearchMinConeAngle = 5.0;

	// How smoothly to follow the rotation of the search swiveling. Lower values means more loose, and higher is more snappy.
	float SearchRotateInterpSpeed = 10.0;

	float SpotLightInitialConeAngle;
	FRotator SpotLightInitialRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TurretHitResponseComponent.OnHackableSniperTurretHit.AddUFunction(this, n"OnHitBySniperTurret");

		//SpotLightInitialConeAngle = SpotLight.OuterConeAngle;
		//SpotLightInitialRelativeRotation = SpotLight.GetRelativeRotation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		FTemporalLog CameraSection = TemporalLog.Section("Camera", 0);
		CameraSection.Value("Stunned Until Time", StunnedComp.GetStunnedUntilTime());

		for(auto Player : Game::Players)
		{
			if(!IsDetectionEnabledForPlayer(Player))
				continue;

			FPrisonStealthPlayerLastSeen LastSeenData = GetLastSeenData(Player);
			FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
			FTemporalLog PlayerSection = TemporalLog.Section(PlayerName, int(Player.Player) + 1);
			
			PlayerSection.Sphere("Last Seen Location", LastSeenData.Location, MagnetDrone::Radius);
			PlayerSection.Value("Last Seen Time", LastSeenData.Time);
			PlayerSection.Value("Current Time", Time::GetGlobalCrumbTrailTime());

			PlayerSection.Value("Player Is In Sight", IsPlayerInSight(Player));
			PlayerSection.Value("Has Detected Player", HasDetectedPlayer(Player));
			PlayerSection.Value("Detection Alpha", GetDetectionAlpha(Player));
		}
#endif
	}

	UFUNCTION()
	void OnHitBySniperTurret(FHackableSniperTurretHitEventData EventData)
	{
		if(StunnedComp.IsStunned())
		{
			FPrisonStealthCameraOnStunStartedParams Params;
			Params.bReset = true;
			UPrisonStealthCameraEventHandler::Trigger_OnStunStarted(this, Params);
		}

		StunnedComp.StartStun();
		PrisonStealth::GetStealthManager().OnCameraHit(this);
	}

	void Reset() override
	{
		Super::Reset();

		UPrisonStealthCameraEventHandler::Trigger_OnReset(this);
	}
};