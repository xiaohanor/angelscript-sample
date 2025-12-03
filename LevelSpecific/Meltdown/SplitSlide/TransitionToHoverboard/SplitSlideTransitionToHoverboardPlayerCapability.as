struct FSplitSlideJumpArcParams
{
	FVector Location;
	FVector Velocity;
	FRotator Rotation;
	bool bReachedEnd;
}

struct FSplitSlideTransitionToHoverboardDeactivateParams
{
	bool bReachedEnd;
}

class USplitSlideTransitionToHoverboardPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 5;
	default TickGroupSubPlacement = 10;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	ASplitSlideArcActor ArcActor;

	FHazeAcceleratedVector AccOffset;

	float PlayerSign;
	const float SidewaysOffsetDistance = 200.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PlayerSign = Player == Game::Mio ? -1.0 : 1.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		TListedActors<ASplitSlideArcActor> ListedActors;
		auto TempArcActor = ListedActors.Single;

		if (MoveComp.HasMovedThisFrame())
			return false;
		if (TempArcActor == nullptr)
			return false;
		if (!TempArcActor.bPlayerLaunched[Player])
			return false;
		if (Player.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSplitSlideTransitionToHoverboardDeactivateParams& Params) const
	{
		if (GetPlayerTransformAtTime(ActiveDuration).bReachedEnd)
		{
			Params.bReachedEnd = true;
			return true;
		}
		
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (!ArcActor.bPlayerLaunched[Player])
			return true;
		if (Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ASplitSlideArcActor> ListedActors;
		ArcActor = ListedActors.Single;
		FSplitSlideJumpArcParams StartParams = GetPlayerTransformAtTime(0.0);
		FVector RelativeLocation = Player.ActorLocation - StartParams.Location;
		FVector RelativeVelocity = Player.ActorVelocity - StartParams.Velocity;
		AccOffset.SnapTo(RelativeLocation, RelativeVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSplitSlideTransitionToHoverboardDeactivateParams Params)
	{
		if (Params.bReachedEnd)
			Player.KillPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				AccOffset.AccelerateTo(FVector::ZeroVector, 1.0, DeltaTime);
				FSplitSlideJumpArcParams Params = GetPlayerTransformAtTime(ActiveDuration);
				FVector NewLocation = Params.Location;
				NewLocation += AccOffset.Value;
				Movement.AddDeltaFromMoveTo(NewLocation);
				Movement.InterpRotationTo(Params.Rotation.Quaternion(), 1.0, false);
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}
	}

	private FSplitSlideJumpArcParams GetPlayerTransformAtTime(float Time) const
	{
		FVector SidewaysOffset = ArcActor.ActorRightVector * SidewaysOffsetDistance * PlayerSign;
		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = ArcActor.ActorLocation + SidewaysOffset;
		Trajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
			ArcActor.ActorLocation + SidewaysOffset,
			ArcActor.LandingLocationComp.WorldLocation + SidewaysOffset,
			ArcActor.Gravity,
			ArcActor.HorizontalSpeed
		);

		Trajectory.Gravity = FVector::UpVector * ArcActor.Gravity;
		Trajectory.LandLocation = ArcActor.LandingLocationComp.WorldLocation + SidewaysOffset;
		//Trajectory.DrawDebug(FLinearColor::White, 0, 5, 100);

		FRotator Rotation = FRotator::MakeFromXZ(Trajectory.GetVelocity(Time).GetSafeNormal(), FVector::UpVector);

		FSplitSlideJumpArcParams Params;
		Params.Location = Trajectory.GetLocation(Time);
		Params.Velocity = Trajectory.GetVelocity(Time);
		Params.Rotation = Rotation;
		Params.bReachedEnd = Time > Trajectory.GetTotalTime();

		return Params;
	}
};