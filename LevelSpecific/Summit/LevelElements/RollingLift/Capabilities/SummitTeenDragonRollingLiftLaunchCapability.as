class USummitTeenDragonRollingLiftLaunchCapability : UHazePlayerCapability
{
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	UPlayerTeenDragonComponent DragonComp;
	USummitTeenDragonRollingLiftComponent LiftComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	ASummitRollingLift CurrentRollingLift;

	const float DurationLimit = 1.5;
	const float DistCheck = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(LiftComp.CurrentRollingLift == nullptr)
			return false;

		if(!LiftComp.LaunchLocation.IsSet())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(LiftComp.CurrentRollingLift == nullptr)
			return true;

		if(ActiveDuration > 0.5)
		{
			if(MoveComp.HasGroundContact())
				return true;

			if(Player.ActorLocation.DistSquared(LiftComp.LaunchLocation.Value) < Math::Square(DistCheck))
				return true;
		}

		if(ActiveDuration > DurationLimit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		CurrentRollingLift = LiftComp.CurrentRollingLift;
		Player.ApplySettings(SummitRollingLiftGravitySettings, this, EHazeSettingsPriority::Gameplay);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, LiftComp.LaunchLocation.Value, MoveComp.GravityForce, 0);
		Player.SetActorVelocity(LaunchVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		LiftComp.LaunchLocation.Reset();
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, LiftComp.LaunchLocation.Value, MoveComp.GravityForce, 0);
				// Movement.AddHorizontalVelocity(LaunchVelocity);
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();
				
				// TEMPORAL_LOG(Player)
				// 	.Arrow("Rolling Lift: Launch Velocity", Player.ActorLocation, Player.ActorLocation + LaunchVelocity, false, 20, 40, FLinearColor::White)
				// ;

				// // Make the velocity follow the spline
				// {
				// 	const FVector PendingDelta = CurrentVelocity * DeltaTime;
				// 	const FVector PendingLocation = Player.ActorLocation + PendingDelta;
				// 	const FSplinePosition SplinePosition = CurrentRollingLift.FindBestGuideSpline(PendingLocation, CurrentSpline);
				// 	const FVector DeltaToSpline = CurrentRollingLift.GetLockedDeltaToSpline(SplinePosition, PendingLocation);
				// 	Movement.AddDeltaWithCustomVelocity(DeltaToSpline, FVector::ZeroVector);

				// 	TEMPORAL_LOG(Player)
				// 		.Arrow("Rolling Lift: CurrentVelocity", Player.ActorLocation, Player.ActorLocation + CurrentVelocity, false, 20, 40, FLinearColor::White)
				// 		.Arrow("Rolling Lift: DeltaToSpline", Player.ActorLocation, Player.ActorLocation + DeltaToSpline, false, 20, 40, FLinearColor::Teal)
				// 		.Sphere("Rolling Lift: Guide Spline Position", SplinePosition.WorldLocation, 200, FLinearColor::Blue, 20)
				// 		.Value("Rolling Lift: Guide Spline Distance", SplinePosition.CurrentSplineDistance)
				// 	;

				// 	CurrentRollingLift.LastSplineForward = SplinePosition.WorldForwardVector;
				// }
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
	
};