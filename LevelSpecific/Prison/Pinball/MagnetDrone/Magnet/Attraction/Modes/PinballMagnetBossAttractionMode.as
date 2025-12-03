enum EPinballMagnetBossAttractionState
{
	FlyTowardsCamera,
	LaunchIntoBoss
};

/**
 * Attract to the APinballBoss actor (the boss in the background)
 * Will first fly out towards the camera, then launch back into the boss.
 */
class UPinballMagnetBossAttractionMode : UMagnetDroneAttractionMode
{
	default TickOrder = 70;

#if !RELEASE
	default DebugColor = FLinearColor::Red;
#endif

	UPinballMagnetDroneComponent PinballComp;

	EPinballMagnetBossAttractionState AttractionState;

	// FlyTowardsCamera
	FHazeAcceleratedVector AccLocation;
	const float FlyTowardsCameraDuration = 0.01;
	const float FlyOutDistanceFromBoss = 0.01;
	const float FlyTowardsCameraMaxAlpha = 0.01;

	// LaunchIntoBoss
	float LaunchIntoBossStartTime;
	FVector LaunchIntoBossStartLocation;
	FHazeAcceleratedVector AccLaunchIntoBossOffset;
	const float LaunchIntoBossDuration = 0.3;

	void Setup(FMagnetDroneAttractionModeSetupParams Params) override
	{
		Super::Setup(Params);
		
		PinballComp = UPinballMagnetDroneComponent::Get(Params.Player);
	}

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Params.AimData.GetActor().IsA(APinballBoss))
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		PrepareFlyTowardsCamera(Params);

		return true;
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) override
	{
		switch(AttractionState)
		{
			case EPinballMagnetBossAttractionState::FlyTowardsCamera:
				return TickFlyTowardsCamera(Params, DeltaTime, AttractionAlpha);

			case EPinballMagnetBossAttractionState::LaunchIntoBoss:
				return TickLaunchIntoBoss(Params, DeltaTime, AttractionAlpha);
		}
	}

	void PrepareFlyTowardsCamera(FMagnetDroneAttractionModePrepareAttractionParams Params)
	{
		AttractionState = EPinballMagnetBossAttractionState::FlyTowardsCamera;
		AccLocation.SnapTo(Params.InitialLocation, Params.InitialVelocity);
	}

	void PrepareLaunchIntoBoss(FMagnetDroneAttractionModeTickAttractionParams Params)
	{
		AttractionState = EPinballMagnetBossAttractionState::LaunchIntoBoss;
		LaunchIntoBossStartTime = Params.CurrentGameTime;
		LaunchIntoBossStartLocation = Params.CurrentLocation;
		AccLaunchIntoBossOffset.SnapTo(FVector::ZeroVector, Params.CurrentVelocity);
	}

	FVector TickFlyTowardsCamera(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		FVector TargetLocation = GetTargetInFrontOfCameraLocation();
		AccLocation.SpringTo(TargetLocation, 20, 0.2, DeltaTime);

#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog();
		TemporalLog.Sphere("TickFlyTowardsCamera;TargetLocation", TargetLocation, MagnetDrone::Radius);
		TemporalLog.Sphere("TickFlyTowardsCamera;AccLocation", AccLocation.Value, MagnetDrone::Radius);
#endif

		if(Params.ActiveDuration > FlyTowardsCameraDuration)
		{
			AttractionAlpha = FlyTowardsCameraMaxAlpha;
			PrepareLaunchIntoBoss(Params);
		}
		else
		{
			AttractionAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(0, FlyTowardsCameraMaxAlpha), Params.ActiveDuration / FlyTowardsCameraDuration);
			const FPlane CameraPlane = FPlane(GetTargetInFrontOfCameraLocation(), FVector::ForwardVector);
			
			if(CameraPlane.PlaneDot(Params.CurrentLocation) < 0)
			{
				AttractionAlpha = FlyTowardsCameraMaxAlpha;
				PrepareLaunchIntoBoss(Params);
			}
		}

		return AccLocation.Value;
	}

	FVector GetTargetInFrontOfCameraLocation() const
	{
		const FVector CameraLocation = Game::Zoe.ViewLocation;
		const FVector DownOffset = FVector::DownVector * 300;
		FVector Location = CameraLocation + DownOffset;
		Location.X = -FlyOutDistanceFromBoss;
		return Location;
	}

	FVector TickLaunchIntoBoss(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		const float LaunchTime = Params.CurrentGameTime - LaunchIntoBossStartTime;
		const float Alpha = Math::Pow(Math::Saturate(LaunchTime / LaunchIntoBossDuration), 2);

		AttractionAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(FlyTowardsCameraMaxAlpha, 1.0), Alpha);

		FVector Location = Math::Lerp(LaunchIntoBossStartLocation, AttractionTarget.GetTargetLocation(), Alpha);
		AccLaunchIntoBossOffset.SpringTo(FVector::ZeroVector, 40, 0.1, DeltaTime);
		Location = Math::Lerp(Location + AccLaunchIntoBossOffset.Value, Location, Alpha);

#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog();
		TemporalLog.Value("TickLaunchIntoBoss;Alpha", Alpha);
		TemporalLog.Sphere("TickLaunchIntoBoss;Location", Location, MagnetDrone::Radius);
#endif

		return Location;
	}
};