class UPinballMagnetDronePushedByPlungerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	UPinballBallComponent BallComp;
	UPinballMagnetDroneLaunchedComponent LaunchedComp;
	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	APinballPlunger PushingPlunger;
	float InitialHorizontalOffset;
	float InitialAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Player);
		LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(LaunchedComp.PushedByPlunger == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(LaunchedComp.PushedByPlunger == nullptr)
			return true;

		if(LaunchedComp.PushedByPlunger != PushingPlunger)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PushingPlunger = LaunchedComp.PushedByPlunger;
		InitialHorizontalOffset = LaunchedComp.InitialHorizontalOffset;
		InitialAlpha = LaunchedComp.InitialAlpha;

		MoveComp.FollowComponentMovement(PushingPlunger.PlungerComp, this, EMovementFollowComponentType::Teleport);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		
		PushingPlunger = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		const FVector Velocity = CalculateVelocity();
		const FVector Delta = CalculateDelta();

		TemporalLog.DirectionalArrow("Calculated Velocity", Owner.ActorLocation, Velocity);
		TemporalLog.DirectionalArrow("Calculated Delta", Owner.ActorLocation, Delta);

		const FVector FullDelta = Delta + (Velocity * Time::GetActorDeltaSeconds(Owner));
		TemporalLog.DirectionalArrow("Full Delta", Owner.ActorLocation, FullDelta);

		TemporalLog.Sphere("Location", Owner.ActorLocation, BallComp.GetRadius());
		TemporalLog.Sphere("Current Launch Location", PushingPlunger.GetCurrentLaunchLocation(Owner.ActorLocation, BallComp.GetRadius()), BallComp.GetRadius());
		TemporalLog.Sphere("Final Launch Location", PushingPlunger.GetFinalLaunchLocation(Owner.ActorLocation, BallComp.GetRadius()), BallComp.GetRadius());
		TemporalLog.Sphere("Location after Delta", Owner.ActorLocation + FullDelta, BallComp.GetRadius());

		FVector RelativeLocation = GetPlungerCompTransform().InverseTransformPositionNoScale(Owner.ActorLocation);
		TemporalLog.Value("RelativeLocation", RelativeLocation);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		check(HasControl());

		if(!MoveComp.PrepareMove(MoveData))
			return;

		const FVector Delta = CalculateDelta();
		const FVector Velocity = CalculateVelocity();
		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		MoveComp.ApplyMove(MoveData);
	}

	private FVector CalculateVelocity() const
	{
		const FTransform PlungerCompTransform = GetPlungerCompTransform();
		FVector Velocity = Owner.GetActorVelocity();
		FVector RelativeVelocity = PlungerCompTransform.InverseTransformVectorNoScale(Velocity);

		RelativeVelocity.X = 0;
		
		// Prevent horizontal movement along the paddle
		RelativeVelocity.Y = 0;

		const FVector TargetLaunchLocation = PushingPlunger.GetCurrentLaunchLocation(Owner.ActorLocation, BallComp.GetRadius());
		const FVector TargetRelativeLaunchLocation = PlungerCompTransform.InverseTransformPositionNoScale(TargetLaunchLocation);
		FVector RelativeLocation = PlungerCompTransform.InverseTransformPositionNoScale(Owner.ActorLocation);
		if(RelativeLocation.Z < TargetRelativeLaunchLocation.Z)
		{
			RelativeVelocity.Z = 0;
			RelativeLocation.Z = TargetRelativeLaunchLocation.Z;
		}

		Velocity = PlungerCompTransform.TransformVectorNoScale(RelativeVelocity);

		check(!Velocity.ContainsNaN());
		return Velocity;
	}

	private FVector CalculateDelta() const
	{
		const FVector TargetLaunchLocation = PushingPlunger.GetCurrentLaunchLocation(Player.ActorLocation, MagnetDrone::Radius);
		FVector RelativeLocation = PushingPlunger.PlungerComp.WorldTransform.InverseTransformPositionNoScale(TargetLaunchLocation);

		if(PushingPlunger.bLerpWhileLaunching)
		{
			// Move in to the center of the plunger over time
			float Alpha = PushingPlunger.GetCurrentLaunchForwardAlpha();
			Alpha = Math::GetPercentageBetweenClamped(InitialAlpha, 1.0, Alpha);
			Alpha = Math::EaseIn(0, 1, Alpha, 1.5);

			check(Alpha == Math::Saturate(Alpha));

			// Lerp horizontally
			const float HorizontalOffset = Math::Lerp(InitialHorizontalOffset, RelativeLocation.Y, Alpha);
			RelativeLocation.Y = HorizontalOffset;
		}

		const FVector NewLocation = PushingPlunger.PlungerComp.WorldTransform.TransformPositionNoScale(RelativeLocation);
		return NewLocation - Player.ActorLocation;
	}

	FTransform GetPlungerCompTransform() const
	{
		return FTransform(
			FQuat::MakeFromZX(PushingPlunger.PlungerComp.UpVector, FVector::UpVector),
			PushingPlunger.PlungerComp.WorldLocation,
			PushingPlunger.PlungerComp.WorldScale
		);
	}
};