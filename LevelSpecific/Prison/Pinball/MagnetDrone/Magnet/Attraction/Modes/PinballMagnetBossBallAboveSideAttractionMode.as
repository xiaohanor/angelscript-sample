enum EPinballMagnetBossBallAboveSideAttractionState
{
	AccelerateToSide,
	LaunchBackTowardsBossBall,
};

/**
 * Attract towards the APinballBossBall actor.
 * Only activate if we are above the boss, and UPinballMagnetBossBallBelowAttractionMode is not active.
 * First, we accelerate out to the closest side of the boss.
 * When we reach the side location, start launching in towards the boss.
 */
class UPinballMagnetBossBallAboveSideAttractionMode : UMagnetDroneAttractionMode
{
	default TickOrder = 90;

#if !RELEASE
	default DebugColor = ColorDebug::Green;
#endif

	UPinballMagnetDroneComponent PinballComp;

	EPinballMagnetBossBallAboveSideAttractionState AttractionState;
	FHazeAcceleratedVector AccLocation;

	// AccelerateToSide
	float DistanceToSide;
	float TimeToReachSide;
	float StartAngle;

	// LaunchBackTowardsBossBall
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

		// We are below the boss ball
		if(Params.PlayerLocation.Z < (PinballBossBall.ActorLocation.Z + PinballBossBall.Sphere.SphereRadius))
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
			case EPinballMagnetBossBallAboveSideAttractionState::AccelerateToSide:
				return TickAccelerateToSide(Params, DeltaTime, AttractionAlpha);

			case EPinballMagnetBossBallAboveSideAttractionState::LaunchBackTowardsBossBall:
				return TickLaunchBackTowardsBossBall(Params, DeltaTime, AttractionAlpha);
		}
	}

	void PrepareAccelerateToSide(FVector Location, FVector Velocity)
	{
		AttractionState = EPinballMagnetBossBallAboveSideAttractionState::AccelerateToSide;

		AccLocation.SnapTo(Location, Velocity);

		StartAngle = (Location - AttractionTarget.GetActor().ActorLocation).GetAngleDegreesTo(AttractionTarget.GetTargetImpactNormal());

		if(Location.Y < AttractionTarget.GetActor().ActorLocation.Y)
			StartAngle *= -1;

		const FVector ToSide = GetTargetSideLocation() - Location;
		DistanceToSide = ToSide.Size();
		const FVector DirToSide = ToSide / DistanceToSide;

		float AttractionSpeed = 1500;
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

		const float Angle = Math::Lerp(StartAngle, 0, Alpha);
		const float RotatingOffsetDistance = Math::Lerp(500, 0, Alpha);
		const FVector RotatingOffset = FQuat(FVector::ForwardVector, Math::DegreesToRadians(Angle)) * (AttractionTarget.GetTargetImpactNormal() * RotatingOffsetDistance);
		//GetTemporalLog().DirectionalArrow("TickAccelerateToSide;RotatingOffset", AttractionComp.GetAttractionTarget().GetTargetLocation(), RotatingOffset, MagnetDrone::Radius);
		TargetLocation = AttractionTarget.GetTargetLocation() + RotatingOffset;

		const float Stiffness = Math::Lerp(10, 70, Alpha);
		const float Damping = Math::Lerp(0, 0.1, Alpha);
		AccLocation.SpringTo(TargetLocation, Stiffness, Damping, DeltaTime);

#if !RELEASE
		GetTemporalLog()
			.Value("TickAccelerateToSide;Alpha", Alpha)
			.Sphere("TickAccelerateToSide;TargetLocation", TargetLocation, MagnetDrone::Radius)
			.Sphere("TickAccelerateToSide;AccLocation", AccLocation.Value, MagnetDrone::Radius);
#endif

		if(Params.ActiveDuration > TimeToReachSide)
		{
			PrepareLaunchBackTowardsBossBall(AccLocation.Value, AccLocation.Velocity, Params.CurrentGameTime);
		}

		return AccLocation.Value;
	}

	void PrepareLaunchBackTowardsBossBall(FVector Location, FVector Velocity, float GameTime)
	{
		AttractionState = EPinballMagnetBossBallAboveSideAttractionState::LaunchBackTowardsBossBall;
		StartLaunchTowardsBossBallTime = GameTime;
		AccRelativeLocation.SnapTo(Location - GetTargetSideLocation(), Velocity);

		const FVector ToBossBall = AttractionTarget.GetActor().ActorLocation - GetTargetSideLocation();
		const float DistanceToBossBall = ToBossBall.Size();

		float AttractionSpeed = 1500;

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

#if !RELEASE
		GetTemporalLog().Value("TickLaunchBackTowardsBossBall;Alpha", Alpha)
			.Sphere("TickLaunchBackTowardsBossBall;Location", Location, MagnetDrone::Radius)
			.DirectionalArrow("TickLaunchBackTowardsBossBall;AccRelativeLocation", Location, AccRelativeLocation.Value)
			.Sphere("TickLaunchBackTowardsBossBall;FinalLocation", Location, MagnetDrone::Radius)
		;
#endif
		
		return Location;
	}

	FVector GetTargetSideLocation() const
	{
		return AttractionTarget.GetTargetLocation() + AttractionTarget.GetTargetImpactNormal() * 300;
	}
};