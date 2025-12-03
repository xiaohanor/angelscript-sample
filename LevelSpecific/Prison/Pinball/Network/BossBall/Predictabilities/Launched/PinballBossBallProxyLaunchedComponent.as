UCLASS(NotBlueprintable)
class UPinballBossBallProxyLaunchedComponent : UPinballBossBallProxyComponent
{
	default ControlComponentClass = UPinballBossBallLaunchedComponent;

	bool bIsLaunched = false;
	bool bHasBeenConsumed = false;
	float LaunchedTime;
	FPinballBallLaunchData LaunchData;
	uint LaunchedFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballBossBallProxyLaunchedComponent");
#endif
	}

	void InitComponentState(const UActorComponent ControlComp) override
	{
		const auto ControlLaunchedComp = Cast<UPinballBossBallLaunchedComponent>(ControlComp);
		
		LaunchedTime = ControlLaunchedComp.LaunchedTime;
		LaunchData = ControlLaunchedComp.LaunchData;

		LaunchedFrame = ControlLaunchedComp.LaunchedFrame + 2;
		if(WasLaunchedThisFrame())
			bHasBeenConsumed = false;

		bIsLaunched = ControlLaunchedComp.bIsLaunched;

		Super::InitComponentState(ControlComp);
	}

#if !RELEASE
	void LogComponentState(FTemporalLog TemporalLog) const override
	{
		Super::LogComponentState(TemporalLog);

		TemporalLog.Value(f"LaunchedTime", LaunchedTime)
			.Sphere(f"LaunchLocation", LaunchData.LaunchLocation, APinballBossBall::Radius)
			.Value(f"WasLaunchedBy", LaunchData.LaunchedBy)
			.Value(f"FromBallSide", LaunchData.bFromBallSide)
			.Value(f"LaunchedFrame", LaunchedFrame)
			.Value(f"TickFrameNumber", Proxy.SubframeNumber)
			.DirectionalArrow(f"LaunchImpulse", LaunchData.LaunchLocation, LaunchData.LaunchVelocity)

			.Value(f"WasLaunchedThisFrame", WasLaunchedThisFrame())
			.Value(f"WasLaunched", WasLaunched())

			.Value(f"bIsLaunched", bIsLaunched)
		;
	}
#endif

	bool WasLaunched() const
	{
		if(LaunchData.LaunchedBy == nullptr)
			return false;

		check(LaunchedFrame > 0);

		return true;
	}

	bool HasLaunchToConsume() const
	{
		if(bHasBeenConsumed)
			return false;

		if(!WasLaunchedThisFrame())
			return false;

		return true;
	}

	bool WasLaunchedThisFrame() const
	{
		if(!WasLaunched())
			return false;

		// We also accept hits from the previous frame, to basically ignore tick order
		if(Proxy.SubframeNumber - LaunchedFrame <= 1)
			return true;

		return false;
	}

	FVector GetLaunchDirection() const
	{
		return LaunchData.LaunchVelocity.GetSafeNormal();
	}

	void ConsumeLaunch()
	{
		check(!bHasBeenConsumed);
		check(WasLaunchedThisFrame());
		
		// FVector VisualLocation = Proxy.ActorLocation;
		// if(WasLaunchedBy.ShouldLerpBack())
		// {
			// auto BallComp = UPinballBallComponent::Get(MoveComp.Owner);
			// ReturnOffsetDuration = WasLaunchedBy.GetLauncherLerpBackDuration(BallComp);
			// OffsetPlane = LaunchImpulse.GetSafeNormal();
			// AccOffset = VisualLocation - LaunchLocation;
			// AccOffset = AccOffset.VectorPlaneProject(OffsetPlane);
			// AccOffset.X = 0;
		// }

		Proxy.SetActorLocation(LaunchData.LaunchLocation);
		Proxy.SetActorVelocity(LaunchData.LaunchVelocity);

		if(Pinball::bIgnoreCollisionWhenLaunched)
		{
			// Clear any previous ignores
			Proxy.MoveComp.RemoveMovementIgnoresActor(this);

			// Ignore the launcher actor
			Proxy.MoveComp.AddMovementIgnoresActor(this, LaunchData.LaunchedBy.Owner);
		}

		// Just make sure we make the launch data old
		LaunchedFrame -= 2;
		bHasBeenConsumed = true;
	}

	void ResetLaunch()
	{
		if(Pinball::bIgnoreCollisionWhenLaunched)
			Proxy.MoveComp.RemoveMovementIgnoresActor(this);

		LaunchedTime = 0.0;
		LaunchData = FPinballBallLaunchData();
		LaunchedFrame = 0;
		bIsLaunched = false;
	}
};