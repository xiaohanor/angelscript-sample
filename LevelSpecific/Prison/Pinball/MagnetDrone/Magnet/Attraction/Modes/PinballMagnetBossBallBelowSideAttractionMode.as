enum EPinballMagnetBossBallBelowSideAttractionState
{
	AccelerateToSide,
	LaunchBackTowardsBossBall,
};

/**
 * Attract towards the APinballBossBall actor.
 * Only activate if we are below the boss, and UPinballMagnetBossBallBelowAttractionMode is not active.
 *  First, we accelerate out to the closest side of the boss.
 * When we reach the side location, start launching in towards the boss.
 */
class UPinballMagnetBossBallBelowSideAttractionMode : UMagnetDroneAttractionMode
{
	default TickOrder = 90;

#if !RELEASE
	default DebugColor = ColorDebug::Cyan;
#endif
	
	UPinballMagnetDroneComponent PinballComp;

	EPinballMagnetBossBallBelowSideAttractionState AttractionState;
	FHazeAcceleratedVector AccLocation;

	// AccelerateToSide
	float DistanceToSide;
	float TimeToReachSide;
	float StartAngle;

	// LaunchBackTowardsBossBall
	bool bLaunchTowardsBossBall = false;
	float StartLaunchTowardsBossBallTime;
	FHazeAcceleratedVector AccRelativeLocation;
	float TimeToReachBossBall;

	void Setup(FMagnetDroneAttractionModeSetupParams Params) override
	{
		Super::Setup(Params);
		
		PinballComp = UPinballMagnetDroneComponent::Get(Params.Player);
	}

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		const auto PinballBossBall = Cast<APinballBossBall>(Params.AimData.GetActor());
		if(PinballBossBall == nullptr)
			return false;

		// We are above the boss ball
		if(Params.PlayerLocation.Z > (PinballBossBall.ActorLocation.Z + PinballBossBall.Sphere.SphereRadius))
			return false;

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		PrepareAccelerateToSide(Params.InitialLocation, Params.InitialVelocity);

		return true;
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) override
	{
		switch(AttractionState)
		{
			case EPinballMagnetBossBallBelowSideAttractionState::AccelerateToSide:
				return TickAccelerateToSide(Params, DeltaTime, AttractionAlpha);

			case EPinballMagnetBossBallBelowSideAttractionState::LaunchBackTowardsBossBall:
				return TickLaunchBackTowardsBossBall(Params, DeltaTime, AttractionAlpha);
		}
	}

	void PrepareAccelerateToSide(FVector Location, FVector Velocity)
	{
		AttractionState = EPinballMagnetBossBallBelowSideAttractionState::AccelerateToSide;

		AccLocation.SnapTo(Location, Velocity);

		StartAngle = 0;

		const FVector ToSide = GetTargetSideLocation() - Location;
		DistanceToSide = ToSide.Size();
		const FVector DirToSide = ToSide / DistanceToSide;

		float AttractionSpeed = 1000;
		float SpeedTowardsSide = Velocity.DotProduct(DirToSide);

		if(SpeedTowardsSide > 0)
			AttractionSpeed += SpeedTowardsSide;

		if(Math::Abs(StartAngle) > 0)
			TimeToReachSide += (StartAngle * 0.02);

		TimeToReachSide = DistanceToSide / AttractionSpeed;
	}

	FVector TickAccelerateToSide(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		AttractionAlpha = 0;

		const float Alpha = Math::Pow(Math::Saturate(Params.ActiveDuration / TimeToReachSide), 2);

		FVector TargetLocation = GetTargetSideLocation();

		const float Stiffness = Math::Lerp(10, 70, Alpha);
		const float Damping = Math::Lerp(0, 0.1, Alpha);
		AccLocation.SpringTo(TargetLocation, Stiffness, Damping, DeltaTime);

		//GetTemporalLog().Value("TickAccelerateToSide;Alpha", Alpha);
		//GetTemporalLog().Sphere("TickAccelerateToSide;TargetLocation", TargetLocation, MagnetDrone::Radius);
		//GetTemporalLog().Sphere("TickAccelerateToSide;AccLocation", AccLocation.Value, MagnetDrone::Radius);

		if(Params.ActiveDuration > TimeToReachSide)
		{
			SetupLaunchBackTowardsBossBall(AccLocation.Value, AccLocation.Velocity, Params.CurrentGameTime);
		}

		return AccLocation.Value;
	}

	void SetupLaunchBackTowardsBossBall(FVector Location, FVector Velocity, float GameTime)
	{
		AttractionState = EPinballMagnetBossBallBelowSideAttractionState::LaunchBackTowardsBossBall;
		StartLaunchTowardsBossBallTime = GameTime;
		AccRelativeLocation.SnapTo(Location - GetTargetSideLocation(), Velocity);

		const FVector ToBossBall = AttractionTarget.GetActor().ActorLocation - GetTargetSideLocation();
		const float DistanceToBossBall = ToBossBall.Size();

		float AttractionSpeed = 1000;

		float SpeedTowardsSide = Velocity.DotProduct(ToBossBall.GetSafeNormal());

		if(SpeedTowardsSide > 0)
			AttractionSpeed += SpeedTowardsSide;

		TimeToReachBossBall = DistanceToBossBall / AttractionSpeed;
	}

	FVector TickLaunchBackTowardsBossBall(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		const float TimeSinceStateStart = Params.CurrentGameTime - StartLaunchTowardsBossBallTime;
		const float Alpha = Math::Pow(Math::Saturate(TimeSinceStateStart / TimeToReachBossBall), 2);

		AttractionAlpha = Alpha;

		const FVector StartLocation = GetTargetSideLocation();
		const FVector EndLocation = AttractionTarget.GetActor().ActorLocation;

		FVector Location = Math::Lerp(StartLocation, EndLocation, Alpha);
		AccRelativeLocation.SpringTo(FVector::ZeroVector, 50, 0.05, DeltaTime);
		Location = Math::Lerp(Location + AccRelativeLocation.Value, Location, Alpha);

		//GetTemporalLog().Value("TickLaunchBackTowardsBossBall;Alpha", Alpha);
		//GetTemporalLog().Sphere("TickLaunchBackTowardsBossBall;Location", Location, MagnetDrone::Radius);
		//GetTemporalLog().DirectionalArrow("TickLaunchBackTowardsBossBall;AccRelativeLocation", Location, AccRelativeLocation.Value);
		//GetTemporalLog().Sphere("TickLaunchBackTowardsBossBall;FinalLocation", Location, MagnetDrone::Radius);
		
		return Location;
	}

	FVector GetTargetSideLocation() const
	{
		return AttractionTarget.GetTargetLocation() + AttractionTarget.GetTargetImpactNormal() * 200;
	}
};