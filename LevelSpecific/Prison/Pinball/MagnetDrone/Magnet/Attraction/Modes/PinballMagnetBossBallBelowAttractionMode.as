/**
 * Attract towards the APinballBossBall actor.
 * Will accelerate straight towards the target.
 * Only activate if we are below the boss, and either quite far away or really close.
 */
class UPinballMagnetBossBallBelowAttractionMode : UMagnetDroneAttractionMode
{
	default TickOrder = 80;

#if !RELEASE
	default DebugColor = ColorDebug::Blue;
#endif
	
	UPinballMagnetDroneComponent PinballComp;

	FHazeAcceleratedVector AccLocation;

	// LaunchBackTowardsBossBall
	float StartLaunchTowardsBossBallTime;
	float TimeToReachBossBall;

	void Setup(FMagnetDroneAttractionModeSetupParams Params) override
	{
		Super::Setup(Params);
		
		PinballComp = UPinballMagnetDroneComponent::Get(Params.Player);
	}

	protected bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const override
	{
		if(!Super::ShouldActivate(Params))
			return false;

		const auto PinballBossBall = Cast<APinballBossBall>(Params.AimData.GetActor());
		if(PinballBossBall == nullptr)
			return false;

		// We are above the boss ball
		if(Params.PlayerLocation.Z > (PinballBossBall.ActorLocation.Z + PinballBossBall.Sphere.SphereRadius))
			return false;

		const FPlane TargetPlane = FPlane(GetTargetSideLocation(Params.AimData), Params.AimData.GetTargetImpactNormal());

		// If we are far away horizontally
		if(TargetPlane.PlaneDot(Params.PlayerLocation) > 500)
			return true;

		// Or if we are very close
		if(Params.PlayerLocation.Distance(Params.AimData.GetTargetLocation()) < 100)
			return true;

		return false;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) override
	{
		if(!Super::PrepareAttraction(Params, OutPathLength, OutTimeUntilArrival))
			return false;

		StartLaunchTowardsBossBallTime = Params.InitialGameTime;

		const FVector ToBossBall = AttractionTarget.GetActor().ActorLocation - Params.InitialLocation;
		const float DistanceToBossBall = ToBossBall.Size();

		float AttractionSpeed = 2000;

		float SpeedTowardsSide = Params.InitialVelocity.DotProduct(ToBossBall.GetSafeNormal());

		if(SpeedTowardsSide > 0)
			AttractionSpeed += SpeedTowardsSide;

		TimeToReachBossBall = DistanceToBossBall / AttractionSpeed;

		return true;
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) override
	{
		const float TimeSinceStateStart = Params.CurrentGameTime - StartLaunchTowardsBossBallTime;
		const float Alpha = Math::Pow(Math::Saturate(TimeSinceStateStart / TimeToReachBossBall), 2);

		AttractionAlpha = Alpha;

		const FVector StartLocation = GetStartLocation();
		const FVector EndLocation = AttractionTarget.GetActor().ActorLocation;

		FVector Location = Math::Lerp(StartLocation, EndLocation, Alpha);

		//GetTemporalLog().Value("TickLaunchStraightTowardsBossBall;Alpha", Alpha);
		//GetTemporalLog().Sphere("TickLaunchStraightTowardsBossBall;Location", Location, MagnetDrone::Radius);
		//GetTemporalLog().DirectionalArrow("TickLaunchStraightTowardsBossBall;AccRelativeLocation", Location, AccRelativeLocation.Value);
		//GetTemporalLog().Sphere("TickLaunchStraightTowardsBossBall;FinalLocation", Location, MagnetDrone::Radius);
		//GetTemporalLog().DirectionalArrow("TickLaunchStraightTowardsBossBall;DeltaMove", Player.ActorLocation, DeltaMove);

		return Location;
	}

	FVector GetTargetSideLocation(FMagnetDroneTargetData TargetData) const
	{
		return TargetData.GetTargetLocation() + TargetData.GetTargetImpactNormal() * 200;
	}
};