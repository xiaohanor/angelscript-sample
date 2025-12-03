struct FSummitDarkCaveChainedBallLandInGoalActivationParams
{
	ASummitDarkCaveChainedBallGoal TargetGoal;
}

class USummitDarkCaveChainedBallLandInGoalCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	ASummitDarkCaveChainedBall Ball;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	FHazeAcceleratedVector AccLocation;

	ASummitDarkCaveChainedBallGoal Goal;

	const float GoalVelocity = 45.0;

	bool bReachedGoal;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitDarkCaveChainedBall>(Owner);

		MoveComp = UHazeMovementComponent::Get(Ball);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitDarkCaveChainedBallLandInGoalActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Ball.bIsChained)
			return false;

		if (bReachedGoal)
			return false;
		
		auto GroundImpacts = MoveComp.GetAllGroundImpacts();
		for(auto GroundImpact : GroundImpacts)
		{
			auto NewGoal = Cast<ASummitDarkCaveChainedBallGoal>(GroundImpact.Actor);
			if(NewGoal != nullptr)
			{
				Params.TargetGoal = NewGoal;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Ball.bIsChained)
			return true;

		if (!bReachedGoal)
			return false;
		else if (bReachedGoal)
			return true;

		auto GroundImpacts = MoveComp.GetAllGroundImpacts();
		for(auto GroundImpact : GroundImpacts)
		{
			if(GroundImpact.Actor.IsA(ASummitDarkCaveChainedBallGoal))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitDarkCaveChainedBallLandInGoalActivationParams Params)
	{
		Goal = Params.TargetGoal;
		AccLocation.SnapTo(Ball.ActorLocation, Ball.ActorVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Goal.BP_DeactivateGoal();
		Goal.StartSinking();
		Ball.bLandedInGoal = true;
		Ball.AttachToActor(Goal, NAME_None, EAttachmentRule::KeepWorld);
		Goal.BP_ActivateGoal();

		FSummitDarkCaveChainedBallLandedInGoalParams EventParams;
		EventParams.GoalLocation = Goal.ActorLocation;
		USummitDarkCaveChainedBallEventHandler::Trigger_OnBallLandedInGoal(Ball, EventParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				AccLocation.SpringTo(Goal.BallTargetLocation.WorldLocation, GoalVelocity, 0.5, DeltaTime);
				Movement.AddDelta(AccLocation.Value - Ball.ActorLocation);

				Movement.AddPendingImpulses();

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);

			bReachedGoal = (Goal.BallTargetLocation.WorldLocation - Ball.ActorLocation).Size() < 20.0;
			Ball.bLandedInGoal = bReachedGoal;
		}
	}
};