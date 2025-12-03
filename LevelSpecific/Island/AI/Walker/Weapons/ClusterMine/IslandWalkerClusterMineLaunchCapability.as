class UIslandWalkerClusterMineLaunchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local; // Lots of mines, move them locally

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	AIslandWalkerClusterMine Mine;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	FWalkerArenaLanePosition TargetLanePos;
	float TargetLaneSpeed; 	
	float LaneOffset;

	FVector LaunchLoc;
	FVector LaunchControl;
	FVector LandTangent;

	float AlphaPerSecond;
	float Alpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandWalkerClusterMine>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Mine.bLaunched)
			return false;
		if (Mine.Target == nullptr)
			return false;
		if (Mine.bLanded)
			return false;
		if (Mine.bBounced)
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Mine.bLaunched)
			return true;
		if (Mine.bLanded)
			return true;
		if (Mine.bBounced)
			return true;
		if (MoveComp.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AddMovementIgnoresActor(this, Mine.ProjectileComp.Launcher);

		LaunchLoc = Owner.ActorLocation;
		LaunchControl = LaunchLoc + Mine.ProjectileComp.Velocity;
		LandTangent = FVector(0.0, 0.0, -1000.0);

		TargetLanePos = Mine.Arena.GetPositionAtLane(Mine.Target.ActorLocation, Mine.LanePosition);
		TargetLaneSpeed = 0.0;	
		LaneOffset = Mine.Arena.GetLaneDelta(TargetLanePos, Mine.LanePosition.DistanceAlongLane);

		Alpha = 0.0;
		FWalkerArenaLanePosition OffsetLanePos = TargetLanePos;
		OffsetLanePos.DistanceAlongLane += LaneOffset;
		FVector TargetLocation = Mine.Arena.GetLaneWorldLocation(OffsetLanePos);
		float CurveLength = BezierCurve::GetLength_2CP(LaunchLoc, LaunchControl, TargetLocation - LandTangent, TargetLocation);
		AlphaPerSecond = Mine.ProjectileComp.Velocity.Size() / Math::Max(1.0, CurveLength);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;		

		if (DeltaTime == 0.0)
			return;

		// Launched, but not landed. Follow bezier curve.
		Alpha += AlphaPerSecond * DeltaTime;
		TargetLanePos = Mine.Arena.GetPositionAtLane(Mine.Target.ActorLocation, TargetLanePos);	
		// TODO: Limit target lane position movement by accelerated speed so it can't snap around 

		FWalkerArenaLanePosition OffsetLanePos = TargetLanePos;
		OffsetLanePos.DistanceAlongLane += LaneOffset;
		FVector TargetLocation = Mine.Arena.GetLaneWorldLocation(OffsetLanePos);
		FVector NewLoc = BezierCurve::GetLocation_2CP(LaunchLoc, LaunchControl, TargetLocation - LandTangent, TargetLocation, Alpha); 
		Movement.AddDelta(NewLoc - Owner.ActorLocation);

		MoveComp.ApplyMove(Movement);

		if (Alpha > 0.25)
		{
			if (MoveComp.HasAnyValidBlockingImpacts())
			{
				// Bounce if high up on a wall
				if (MoveComp.HasImpactedWall() && (Mine.Arena != nullptr) && (Owner.ActorLocation.Z > Mine.Arena.Height + 500.0))
					Mine.Bounce();
				else
					Mine.Land(); // Land on obstruction
			}
			else if (Alpha > 1.0)			
			{
				// Stop at end of curve
				Mine.Land();
			}
			else 
			{
				Mine.ProjectileComp.Velocity = MoveComp.Velocity;
			}
		}

		// Align mesh with velocity while falling and right it when landed.
		FRotator MeshRot = Mine.Mesh.WorldRotation;
		if (!Mine.ProjectileComp.Velocity.IsNearlyZero(1.0))
			MeshRot = FRotator::MakeFromZX(-Mine.ProjectileComp.Velocity, Owner.ActorForwardVector);
		Mine.Mesh.SetWorldRotation(MeshRot);

#if EDITOR
		if (Mine.ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
			BezierCurve::DebugDraw_2CP(LaunchLoc, LaunchControl, TargetLocation - LandTangent, TargetLocation, FLinearColor::Purple, 5.0);
		}
#endif
	}
}
