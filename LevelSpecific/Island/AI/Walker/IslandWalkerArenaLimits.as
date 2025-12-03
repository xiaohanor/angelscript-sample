event void FIslandWalkerArenaPhaseChange(EIslandWalkerPhase NewPhase);
event void FIslandWalkerOnSuspendedFallStart();

struct FWalkerArenaLanePosition
{
	float DistanceAlongLane;
	float LaneOutsideDistance; // Currently we only support non-negative outside distances
}

class AIslandWalkerArenaLimits : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent InnerSize;
	default InnerSize.CollisionProfileName = n"NoCollision";
	default InnerSize.ShapeColor = FColor::Green;
	default InnerSize.RelativeLocation = FVector(0.0, 0.0, -1950.0);
	default InnerSize.BoxExtent = FVector(2350.0, 1650.0, 2000.0);

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterSize;
	default OuterSize.CollisionProfileName = n"NoCollision";
	default OuterSize.ShapeColor = FColor::Red;
	default OuterSize.BoxExtent = FVector(3800.0, 3000.0, 40.0);

	UPROPERTY(DefaultComponent)
	UBoxComponent LeftCage;
	default LeftCage.CollisionProfileName = n"NoCollision";
	default LeftCage.ShapeColor = FColor::Yellow;
	default LeftCage.BoxExtent = FVector(400.0, 700.0, 400.0);
	default LeftCage.RelativeLocation = FVector(0.0, -3200.0, 2200.0);

	UPROPERTY(DefaultComponent)
	UBoxComponent RightCage;
	default RightCage.CollisionProfileName = n"NoCollision";
	default RightCage.ShapeColor = FColor::Yellow;
	default RightCage.BoxExtent = FVector(400.0, 700.0, 400.0);
	default RightCage.RelativeLocation = FVector(0.0, 3200.0, 2200.0);

	UPROPERTY(DefaultComponent)
	USceneComponent PoolSurface;
	default PoolSurface.RelativeLocation = FVector(0.0, 0.0, -300.0);

	UPROPERTY(DefaultComponent)
	USceneComponent PoolSurfaceFlooded;
	default PoolSurfaceFlooded.RelativeLocation = FVector(0.0, 0.0, 515.0);

	UPROPERTY(DefaultComponent)
	USceneComponent MioLaunchArea;
	default MioLaunchArea.RelativeLocation = FVector(0.0, -2750.0, 600.0);

	UPROPERTY(DefaultComponent)
	USceneComponent ZoeLaunchArea;
	default ZoeLaunchArea.RelativeLocation = FVector(0.0, 2750.0, 600.0);

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CablesRail;
	default CablesRail.RelativeLocation = FVector(0.0, 0.0, 4010.0);
	default CablesRail.SplineSettings.bClosedLoop = true;
	default CablesRail.SplinePoints.SetNum(8);
	default CablesRail.SplinePoints[0] = FHazeSplinePoint(FVector(3040.0, 2070.0, 0.0));
	default CablesRail.SplinePoints[1] = FHazeSplinePoint(FVector(2840.0, 2270.0, 0.0));
	default CablesRail.SplinePoints[2] = FHazeSplinePoint(FVector(-2840.0, 2270.0, 0.0));
	default CablesRail.SplinePoints[3] = FHazeSplinePoint(FVector(-3040.0, 2070.0, 0.0));
	default CablesRail.SplinePoints[4] = FHazeSplinePoint(FVector(-3040.0, -2070.0, 0.0));
	default CablesRail.SplinePoints[5] = FHazeSplinePoint(FVector(-2840.0, -2270.0, 0.0));
	default CablesRail.SplinePoints[6] = FHazeSplinePoint(FVector(2840.0, -2270.0, 0.0));
	default CablesRail.SplinePoints[7] = FHazeSplinePoint(FVector(3040.0, -2070.0, 0.0));

	UPROPERTY(EditAnywhere)
	TArray<ARespawnPoint> RespawnPoints;

	UPROPERTY(EditAnywhere)
	TArray<AIslandWalkerEscapeSpline> EscapeOrder;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeCameraActor> PhaseTransitionCameraActors;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> OnHeadCameraShake;

	UPROPERTY(EditInstanceOnly)
	UHazeCameraSpringArmSettingsDataAsset OnHeadCameraSettings;

	UPROPERTY(EditInstanceOnly)
	UHazeCameraSpringArmSettingsDataAsset OnHeadCloseCameraSettings;

	TArray<FWalkerArenaRespawnpoints> RespawnPointsBySide;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(3.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 150.0);
#endif	

	UPROPERTY()
	FIslandWalkerArenaPhaseChange OnPhaseChange;

	UPROPERTY()
	FIslandWalkerOnSuspendedFallStart OnSuspendedFallStart;

	bool bIsFlooded = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		CablesRail.UpdateSpline();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Sort respawn points on arena side
		RespawnPointsBySide.SetNum(4);
		for (ARespawnPoint RespawnPoint : RespawnPoints)
		{
			EWalkerArenaSide Side = GetSide(RespawnPoint.ActorLocation);
			RespawnPointsBySide[Side].Points.Add(RespawnPoint);
		}
	}

	EWalkerArenaSide GetSide(FVector Location)
	{
		FVector WorldOffset = Location - InnerSize.WorldLocation;
		float FwdDot = ActorForwardVector.DotProduct(WorldOffset);
		float RightDot = ActorRightVector.DotProduct(WorldOffset);
		if (Math::Abs(FwdDot / InnerSize.BoxExtent.X) > Math::Abs(RightDot / InnerSize.BoxExtent.Y))
			return (FwdDot > 0.0) ? EWalkerArenaSide::Front : EWalkerArenaSide::Rear;
		else
			return (RightDot > 0.0) ? EWalkerArenaSide::Right : EWalkerArenaSide::Left;
	}

	FVector GetLocationAlongInnerEdge(FVector Location, float OutsideOffset = 0.0)
	{
		FVector EdgeStart, EdgeEnd;
		GetInnerEdge(Location, EdgeStart, EdgeEnd, OutsideOffset);
		FVector EdgeLoc;
		float Dummy;
		Math::ProjectPositionOnLineSegment(EdgeStart, EdgeEnd, Location, EdgeLoc, Dummy);
		return EdgeLoc;
	}
 
	FVector GetAtArenaHeight(FVector Location) const
	{
		return FVector(Location.X, Location.Y, Height);
	}

	float GetHeight() const property
	{
		return ActorLocation.Z;
	}

	float GetPoolSurfaceHeight() const property
	{
		return PoolSurface.WorldLocation.Z;
	}

	float GetFloodedPoolSurfaceHeight() const property
	{
		return PoolSurfaceFlooded.WorldLocation.Z;
	}

	FVector GetAtPoolDepth(FVector Location, float Depth) const
	{
		return FVector(Location.X, Location.Y, PoolSurfaceHeight - Depth);
	}

	FVector GetAtFloodedPoolDepth(FVector Location, float Depth) const
	{
		return FVector(Location.X, Location.Y, FloodedPoolSurfaceHeight - Depth);
	}

	float GetFloodedSubmergedDepth(AHazeActor WalkerHead) const
	{
		return (FloodedPoolSurfaceHeight - WalkerHead.ActorLocation.Z + 290.0);	
	}

	FVector ClampToArena(FVector Location)
	{
		FVector Offset = Location - OuterSize.WorldLocation; 
		FVector Clamped = OuterSize.WorldLocation;
		float FwdDistance = OuterSize.ForwardVector.DotProduct(Offset);
		Clamped += OuterSize.ForwardVector * Math::Clamp(FwdDistance, -OuterSize.BoxExtent.X, OuterSize.BoxExtent.X);
		float RightDistance = OuterSize.RightVector.DotProduct(Offset);
		Clamped += OuterSize.RightVector * Math::Clamp(RightDistance, -OuterSize.BoxExtent.Y, OuterSize.BoxExtent.Y);
		Clamped.Z = Math::Clamp(Location.Z, Height, Height + 3000.0);
		return Clamped;
	}

	FVector ClampToInnerArena(FVector Location, float OutsideThreshold = 0.0)
	{
		FVector Offset = Location - InnerSize.WorldLocation; 
		FVector Clamped = InnerSize.WorldLocation;
		float FwdDistance = InnerSize.ForwardVector.DotProduct(Offset);
		Clamped += InnerSize.ForwardVector * Math::Clamp(FwdDistance, -InnerSize.BoxExtent.X, InnerSize.BoxExtent.X);
		float RightDistance = OuterSize.RightVector.DotProduct(Offset);
		Clamped += InnerSize.RightVector * Math::Clamp(RightDistance, -InnerSize.BoxExtent.Y, InnerSize.BoxExtent.Y);
		Clamped.Z = Math::Clamp(Location.Z, Height, Height + 3000.0);
		return Clamped;
	}

	bool IsWithinInnerEdge(FVector Location, float MedialThreshold = 0.0, float LateralThreshold = 0.0)
	{
		FVector WorldOffset = Location - InnerSize.WorldLocation;
		float LocalFwdOffset = InnerSize.WorldRotation.ForwardVector.DotProduct(WorldOffset);
		if (Math::Abs(LocalFwdOffset) > InnerSize.BoxExtent.X + MedialThreshold)
			return false;
		float LocalRightOffset = InnerSize.WorldRotation.RightVector.DotProduct(WorldOffset);
		if (Math::Abs(LocalRightOffset) > InnerSize.BoxExtent.Y + LateralThreshold)
			return false;
		return true;
	}

	void GetInnerEdge(FVector TargetLoc, FVector& EdgeStart, FVector& EdgeEnd, float OutsideOffset = 0.0)
	{
		FVector Offset = TargetLoc - InnerSize.WorldLocation;
		float FwdDot = InnerSize.WorldRotation.ForwardVector.DotProduct(Offset);
		float SideDot = InnerSize.WorldRotation.RightVector.DotProduct(Offset);
		if (Math::Abs(FwdDot / InnerSize.BoxExtent.X) > Math::Abs(SideDot / InnerSize.BoxExtent.Y))
			GetMedialEdge(InnerSize, (FwdDot < 0.0) ? -1.0 : 1.0, OutsideOffset, EdgeStart, EdgeEnd);
		else
			GetLateralEdge(InnerSize, (SideDot < 0.0) ? -1.0 : 1.0, OutsideOffset, EdgeStart, EdgeEnd);

		EdgeStart.Z = Height;
		EdgeEnd.Z = Height;

		// Edge start should be the edge closest to target location
		if (EdgeStart.DistSquared(TargetLoc) > EdgeEnd.DistSquared(TargetLoc))
		{
			FVector StartCopy = EdgeStart;
			EdgeStart = EdgeEnd;
			EdgeEnd = StartCopy;			
		}
	}

	FVector GetInnerEdgeLocationFromRay(FVector Start, FVector Direction, float OutsideOffset = 0.0)
	{
		if (Direction.DotProduct(FVector::UpVector) > 0.9999)
			return ClampToInnerArena(Start, OutsideOffset); // Almost straight up, just use edge closest to start

		if (IsWithinInnerEdge(Start, OutsideOffset, OutsideOffset))
		{
			// Inside, find edge intersection
			FVector RayPlaneNormal = Direction.CrossProduct(FVector::UpVector);
			FVector Intersect;
			FVector EdgeStart;
			FVector EdgeEnd;

			GetMedialEdge(InnerSize, (InnerSize.WorldRotation.ForwardVector.DotProduct(Direction) > 0.0 ? 1.0 : -1.0), OutsideOffset, EdgeStart, EdgeEnd);
			if (Math::IsLineSegmentIntersectingPlane(EdgeStart, EdgeEnd, RayPlaneNormal, Start, Intersect))
				return Intersect; // Intersected back of front edge
			GetLateralEdge(InnerSize, (InnerSize.WorldRotation.RightVector.DotProduct(Direction) > 0.0 ? 1.0 : -1.0), OutsideOffset, EdgeStart, EdgeEnd);
			if (Math::IsLineSegmentIntersectingPlane(EdgeStart, EdgeEnd, RayPlaneNormal, Start, Intersect))
				return Intersect; // Intersected back of front edge
			
			// Either of the above should have intersected!
			check(false);
			return ClampToInnerArena(Start, OutsideOffset);
		}
		else
		{
			// Outside, just clamp start to edge
			return ClampToInnerArena(Start, OutsideOffset);
		}
	}

	private void GetMedialEdge(UBoxComponent Box, float Dir, float OutSideOffset, FVector& EdgeStart, FVector& EdgeEnd)
	{
		FVector EdgeCenter = Box.WorldLocation + Box.WorldRotation.ForwardVector * (Box.BoxExtent.X + OutSideOffset) * Dir;
		EdgeStart = EdgeCenter - Box.WorldRotation.RightVector * (Box.BoxExtent.Y + OutSideOffset);
		EdgeEnd = EdgeCenter + Box.WorldRotation.RightVector * (Box.BoxExtent.Y + OutSideOffset);
	}

	private void GetLateralEdge(UBoxComponent Box, float Dir, float OutSideOffset, FVector& EdgeStart, FVector& EdgeEnd)
	{
		FVector EdgeCenter = Box.WorldLocation + Box.WorldRotation.RightVector * (Box.BoxExtent.Y + OutSideOffset) * Dir;
		EdgeStart = EdgeCenter - Box.WorldRotation.ForwardVector * (Box.BoxExtent.X + OutSideOffset);
		EdgeEnd = EdgeCenter + Box.WorldRotation.ForwardVector * (Box.BoxExtent.X + OutSideOffset);
	}

	AHazePlayerCharacter GetPlayerInLeftCage()
	{
		return GetPlayerInCage(LeftCage);
	}

	AHazePlayerCharacter GetPlayerInRightCage()
	{
		return GetPlayerInCage(RightCage);
	}

	AHazePlayerCharacter GetPlayerInCage(UBoxComponent Cage)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;
			FVector PlayerLocalLoc = Cage.WorldTransform.InverseTransformPosition(Player.ActorCenterLocation);
			if ((Math::Abs(PlayerLocalLoc.X) < Cage.BoxExtent.X) && 
				(Math::Abs(PlayerLocalLoc.Y) < Cage.BoxExtent.Y) &&
				(Math::Abs(PlayerLocalLoc.Z) < Cage.BoxExtent.Z))
				return Player;
		}
		return nullptr;
	}

	FVector GetFloorLocation(FVector Location)
	{
		FVector FloorLoc = GetAtArenaHeight(Location);
		FVector PathLoc;
		if (Pathfinding::FindNavmeshLocation(Location + ActorUpVector * 350.0, 40.0, 400.0, PathLoc))
			FloorLoc.Z = PathLoc.Z;
		return FloorLoc;
	}

	FVector GetAwayFromObstaclesDirection(FVector Location)
	{
		// For now we just slide along pool away from center of current edge
		// TODO: Replace with potential field handling for actual obstacles
		FVector Offset = Location - InnerSize.WorldLocation;
		float FwdDot = InnerSize.WorldRotation.ForwardVector.DotProduct(Offset);
		float SideDot = InnerSize.WorldRotation.RightVector.DotProduct(Offset);

		// Medial edges (fwd/bwd)?		
		if (Math::Abs(FwdDot / InnerSize.BoxExtent.X) > Math::Abs(SideDot / InnerSize.BoxExtent.Y))
			return InnerSize.WorldRotation.RightVector * (SideDot > 0.0 ? 1.0 : -1.0);	 
		// Lateral edges
		return InnerSize.WorldRotation.ForwardVector * (FwdDot > 0.0 ? 1.0 : -1.0);	 
	}

	void DisableRespawnPointsAtSide(FVector Location, FInstigator Instigator)
	{
		EWalkerArenaSide Side = GetSide(Location);
		RespawnPointsBySide[Side].Disable(Instigator);
	}

	void DisbleAllRespawnPoints(FInstigator Instigator)
	{
		for (FWalkerArenaRespawnpoints& Side : RespawnPointsBySide)
		{
			Side.Disable(Instigator);
		}
	}

	void EnableAllRespawnPoints(FInstigator Instigator)
	{
		for (FWalkerArenaRespawnpoints& Side : RespawnPointsBySide)
		{
			Side.Enable(Instigator);
		}
	}

	ARespawnPoint GetBestRespawnPoint(AHazePlayerCharacter Player)
	{
		if (Player.OtherPlayer.IsPlayerDead())
			return nullptr;

		// Use point closest to other player
		ARespawnPoint BestPoint = nullptr;	
		float MinDistSqr = BIG_NUMBER;
		FVector OtherLoc = Player.OtherPlayer.ActorLocation;
		for (FWalkerArenaRespawnpoints Side : RespawnPointsBySide)
		{
			if (Side.Disablers.Num() > 0)
				continue;

			for (ARespawnPoint Point : Side.Points)
			{
				float DistSqr = OtherLoc.DistSquared(Point.ActorLocation);
				if (DistSqr > MinDistSqr)
					continue;
				MinDistSqr = DistSqr;
				BestPoint = Point;		
			}	
		}	
		return BestPoint;
	}

	// Get position in a lane parallell to the inner edge of the arena and curving around the corners
	FWalkerArenaLanePosition GetLanePosition(FVector WorldLocation) const
	{
		FVector Offset = WorldLocation - InnerSize.WorldLocation; 
		float Fwd = InnerSize.ForwardVector.DotProduct(Offset);
		float Right = InnerSize.RightVector.DotProduct(Offset);
	
		// Build a lane starting at front center at a distance that will pass through given location.
		// Lane curves around corners and moves clockwise from starting point.
		FWalkerArenaLanePosition LanePos;
		float MedialOutside = Math::Abs(Fwd) - InnerSize.BoxExtent.X;
		float LateralOutside = Math::Abs(Right) - InnerSize.BoxExtent.Y;
		if ((MedialOutside > 0.0) && (LateralOutside > 0.0))
			LanePos.LaneOutsideDistance = Math::Max(0.0, FVector2D(MedialOutside, LateralOutside).Size()); // At corner curve
		else
			LanePos.LaneOutsideDistance = Math::Max3(0.0, MedialOutside, LateralOutside); // Along side
		float CornerCurveLength = LanePos.LaneOutsideDistance * 0.5 * PI; // Quarter circle

		if ((Fwd > InnerSize.BoxExtent.X - SMALL_NUMBER) && (Right > -SMALL_NUMBER))
		{
			// In Front and to the right
			if (Right < InnerSize.BoxExtent.Y + SMALL_NUMBER)
				LanePos.DistanceAlongLane = Right; // Along front side
			else 
				LanePos.DistanceAlongLane = InnerSize.BoxExtent.Y + CornerCurveLength * Math::Atan2(Right - InnerSize.BoxExtent.Y, Fwd - InnerSize.BoxExtent.X) / (0.5 * PI); // At front right corner
		}
		else if (Right > InnerSize.BoxExtent.Y - SMALL_NUMBER)
		{
			// Along right side
			LanePos.DistanceAlongLane = InnerSize.BoxExtent.Y + CornerCurveLength;
			if (Fwd > -InnerSize.BoxExtent.X - SMALL_NUMBER)
				LanePos.DistanceAlongLane += InnerSize.BoxExtent.X - Fwd; // Along right side, not at corner
			else
				LanePos.DistanceAlongLane += InnerSize.BoxExtent.X * 2.0 + CornerCurveLength * Math::Atan2(-Fwd - InnerSize.BoxExtent.X, Right - InnerSize.BoxExtent.Y) / (0.5 * PI); // Rear right corner	
		}
		else if (Fwd < -InnerSize.BoxExtent.X + SMALL_NUMBER)
		{
			// Along rear side
			LanePos.DistanceAlongLane = InnerSize.BoxExtent.Y + CornerCurveLength * 2.0 + InnerSize.BoxExtent.X * 2.0;
			if (Right > -InnerSize.BoxExtent.Y - SMALL_NUMBER)
				LanePos.DistanceAlongLane += InnerSize.BoxExtent.Y - Right;
			else
				LanePos.DistanceAlongLane += InnerSize.BoxExtent.Y * 2.0 + CornerCurveLength * Math::Atan2(-Right - InnerSize.BoxExtent.Y, -Fwd - InnerSize.BoxExtent.X) / (0.5 * PI); // Rear left corner 	
		}
		else if (Right < -InnerSize.BoxExtent.Y + SMALL_NUMBER)
		{
			// Along left side
			LanePos.DistanceAlongLane = InnerSize.BoxExtent.Y * 3.0 + CornerCurveLength * 3.0 + InnerSize.BoxExtent.X * 2.0;
			if (Fwd < InnerSize.BoxExtent.X + SMALL_NUMBER)
				LanePos.DistanceAlongLane += InnerSize.BoxExtent.X + Fwd; // Along left side, not at corner
			else
				LanePos.DistanceAlongLane += InnerSize.BoxExtent.X * 2.0 + CornerCurveLength * Math::Atan2(Fwd - InnerSize.BoxExtent.X, -Right - InnerSize.BoxExtent.Y) / (0.5 * PI); // Front left corner	
		}
		else
		{
			// Along left front, not at corner
			LanePos.DistanceAlongLane = InnerSize.BoxExtent.Y * 4.0 + CornerCurveLength * 4.0 + InnerSize.BoxExtent.X * 4.0 + Right;
		}
		return LanePos;
	}

	float GetLaneLength(FWalkerArenaLanePosition LanePos) const
	{
		return InnerSize.BoxExtent.Y * 4.0 + InnerSize.BoxExtent.X * 4.0 + Math::Max(0.0, LanePos.LaneOutsideDistance) * 0.5 * PI * 4.0;
	}

	FVector GetLaneWorldLocation(FWalkerArenaLanePosition LanePos) const
	{
		FVector Fwd = InnerSize.ForwardVector;
		FVector Right = InnerSize.RightVector;
		float CornerSin = 0.0;
		float CornerCos = 0.0;
		float OutsideDistance = Math::Max(0.0, LanePos.LaneOutsideDistance); // Currently we only support non-negative outside distances
		float CornerCurveLength = OutsideDistance * 0.5 * PI; // Quarter circle
		float LaneLength = GetLaneLength(LanePos);
		float DistAlongLane = Math::Wrap(LanePos.DistanceAlongLane, 0.0, LaneLength);
		FVector Origin = InnerSize.WorldLocation;
		Origin.Z = Height;

		if (DistAlongLane < InnerSize.BoxExtent.Y) // Front right before corner
			return Origin + Fwd * (InnerSize.BoxExtent.X + OutsideDistance) + Right * DistAlongLane;

		if (DistAlongLane < InnerSize.BoxExtent.Y + CornerCurveLength) // Front right corner
		{
			Math::SinCos(CornerSin, CornerCos, (DistAlongLane - InnerSize.BoxExtent.Y) / OutsideDistance);
			return Origin + Fwd * (InnerSize.BoxExtent.X + CornerCos * OutsideDistance) + Right * (InnerSize.BoxExtent.Y + CornerSin * OutsideDistance);
		}

		if (DistAlongLane < InnerSize.BoxExtent.Y + CornerCurveLength + InnerSize.BoxExtent.X * 2.0) // Right side
			return Origin + Right * (InnerSize.BoxExtent.Y + OutsideDistance) + Fwd * (InnerSize.BoxExtent.Y + CornerCurveLength + InnerSize.BoxExtent.X - DistAlongLane);
		
		if (DistAlongLane < InnerSize.BoxExtent.Y + InnerSize.BoxExtent.X * 2.0 + CornerCurveLength * 2.0) // Rear right corner
		{
			Math::SinCos(CornerSin, CornerCos, (DistAlongLane - (InnerSize.BoxExtent.Y + CornerCurveLength + InnerSize.BoxExtent.X * 2.0)) / OutsideDistance);
			return Origin + Fwd * (-InnerSize.BoxExtent.X - CornerSin * OutsideDistance) + Right * (InnerSize.BoxExtent.Y + CornerCos * OutsideDistance);
		}

		if (DistAlongLane < InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 2.0 + CornerCurveLength * 2.0) // Rear side
		 	return Origin + Fwd * (-InnerSize.BoxExtent.X - OutsideDistance) + Right * (InnerSize.BoxExtent.Y * 2.0 + CornerCurveLength * 2.0 + InnerSize.BoxExtent.X * 2.0 - DistAlongLane);
		
		if (DistAlongLane < InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 2.0 + CornerCurveLength * 3.0) // Rear left corner
		{
			Math::SinCos(CornerSin, CornerCos, (DistAlongLane - (InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 2.0 + CornerCurveLength * 2.0)) / OutsideDistance);
			return Origin + Fwd * (-InnerSize.BoxExtent.X - CornerCos * OutsideDistance) + Right * (-InnerSize.BoxExtent.Y - CornerSin * OutsideDistance);
		}

		if (DistAlongLane < InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 4.0 + CornerCurveLength * 3.0) // Left side
			return Origin + Right * (-InnerSize.BoxExtent.Y - OutsideDistance) + Fwd * (DistAlongLane - (InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 3.0 + CornerCurveLength* 3.0));
		
		if (DistAlongLane < InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 4.0 + CornerCurveLength * 4.0) // Front left corner
		{
			Math::SinCos(CornerSin, CornerCos, (DistAlongLane - (InnerSize.BoxExtent.Y * 3.0 + InnerSize.BoxExtent.X * 4.0 + CornerCurveLength * 3.0)) / OutsideDistance);
			return Origin + Fwd * (InnerSize.BoxExtent.X + CornerSin * OutsideDistance) + Right * (-InnerSize.BoxExtent.Y - CornerCos * OutsideDistance);
		}

		// Front side before center (end of loop)
		return Origin + Fwd * (InnerSize.BoxExtent.X + OutsideDistance) + Right * (DistAlongLane - (InnerSize.BoxExtent.Y * 4.0 + CornerCurveLength * 4.0 + InnerSize.BoxExtent.X * 4.0));
	}

	FWalkerArenaLanePosition GetPositionAtLane(FVector WorldLocation, FWalkerArenaLanePosition Lane) const
	{
		FVector LocAtLane = WorldLocation;
		FVector Offset = (WorldLocation - InnerSize.WorldLocation);
		float Fwd = InnerSize.ForwardVector.DotProduct(Offset);
		float Right = InnerSize.RightVector.DotProduct(Offset);
		float MedialOutside = Math::Abs(Fwd) - InnerSize.BoxExtent.X;
		float LateralOutside = Math::Abs(Right) - InnerSize.BoxExtent.Y;

		if ((MedialOutside > 0.0) && (LateralOutside > 0.0))
		{
			// At corner curve
			FVector Corner = InnerSize.WorldLocation + InnerSize.ForwardVector * InnerSize.BoxExtent.X * Math::Sign(Fwd) + InnerSize.RightVector * InnerSize.BoxExtent.Y * Math::Sign(Right);
			LocAtLane = Corner + (WorldLocation - Corner).GetSafeNormal2D() * Lane.LaneOutsideDistance;
		}
		else  
		{
			// Move to front/rear/left/right plane at outside distance
			FVector Normal = (MedialOutside > LateralOutside) ? InnerSize.ForwardVector * Math::Sign(Fwd) : InnerSize.RightVector * ((Right > 0.0) ? 1.0 : -1.0); 
			float EdgeDist = (MedialOutside > LateralOutside) ? InnerSize.BoxExtent.X : InnerSize.BoxExtent.Y;
			FVector PlaneCenter = InnerSize.WorldLocation + Normal * (EdgeDist + Lane.LaneOutsideDistance);
			LocAtLane = WorldLocation + Normal * Normal.DotProduct(PlaneCenter - WorldLocation);
		}

		return GetLanePosition(LocAtLane);
	}

	float GetLaneDelta(FWalkerArenaLanePosition LanePos, float OtherDistanceAlongLane) const
	{
		float Delta = OtherDistanceAlongLane - LanePos.DistanceAlongLane;
		float LaneLength = GetLaneLength(LanePos);
		if (Math::Abs(Delta) > LaneLength * 0.5)
			Delta -= Math::Sign(Delta) * LaneLength;		
		return Delta;
	}

	void DrawDebugLane(FWalkerArenaLanePosition LanePos, FLinearColor LaneColor = FLinearColor::Purple, FLinearColor PositionColor = FLinearColor::Yellow, float Duration = 0.0, float HeightOffset = 50.0) const
	{
		FVector Offset = FVector(0.0, 0.0, HeightOffset);
		Debug::DrawDebugSphere(GetLaneWorldLocation(LanePos) + Offset, 10.0, 4, PositionColor, 5, Duration);

		FWalkerArenaLanePosition Pos = LanePos;
		Pos.DistanceAlongLane = 0.0;
		FVector PrevLoc = GetLaneWorldLocation(Pos) + Offset;
		float Interval = 20.0;
		Pos.DistanceAlongLane = Interval;
		float LaneLength = GetLaneLength(LanePos);
		for (; Pos.DistanceAlongLane < LaneLength - Interval; Pos.DistanceAlongLane += Interval)
		{
			FVector Loc = GetLaneWorldLocation(Pos) + Offset;
			Debug::DrawDebugLine(PrevLoc, Loc, LaneColor, 3.0, Duration);	
			PrevLoc = Loc;
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (int i = 0; i < 5; i++)
		{
			FWalkerArenaLanePosition  LanePos;
			LanePos.DistanceAlongLane = Time::GameTimeSeconds * 3000.0 * ((i % 2) * 2.0 - 1.0);
			LanePos.LaneOutsideDistance = i * 400.0;
			DrawDebugLane(LanePos);
		}

		FVector CursorOrigin, CursorDirection;
		if (Editor::GetEditorCursorRay(CursorOrigin, CursorDirection))
		{
			FVector CursorLoc = Math::LinePlaneIntersection(CursorOrigin, CursorOrigin + CursorDirection * 10000.0, GetAtArenaHeight(ActorLocation), FVector::UpVector);
			Debug::DrawDebugLine(CursorLoc, CursorLoc + FVector(0.0, 0.0, 400.0), FLinearColor::Red, 3.0);			
			FWalkerArenaLanePosition LanePos = GetLanePosition(CursorLoc);
			if (LanePos.LaneOutsideDistance > 10000.0)
				return;
			DrawDebugLane(LanePos, FLinearColor::DPink, FLinearColor::Red);

			FVector Offset = FVector(0,0,100);
			for (int i = 0; i < 5; i++)
			{
				FWalkerArenaLanePosition LanePos2;
				LanePos2.LaneOutsideDistance = i * 400.0;
				LanePos2 = GetPositionAtLane(CursorLoc, LanePos2);
				Debug::DrawDebugLine(CursorLoc + Offset, GetLaneWorldLocation(LanePos2) + Offset, FLinearColor::Yellow);
				Debug::DrawDebugLine(GetLaneWorldLocation(LanePos2), GetLaneWorldLocation(LanePos2) + Offset * 2.0, FLinearColor::Yellow);
			}

			FWalkerArenaLanePosition LanePos3;
			LanePos3.LaneOutsideDistance = 800.0;
			LanePos3 = GetPositionAtLane(CursorLoc, LanePos3);
			float LaneLength = GetLaneLength(LanePos3);
			float Delta = GetLaneDelta(LanePos3, Math::Wrap(Time::GameTimeSeconds * 100.0, -LaneLength * 0.7, LaneLength * 0.7));
			FWalkerArenaLanePosition OffsetPos = LanePos3;
			OffsetPos.DistanceAlongLane += Delta; 
			Debug::DrawDebugLine(GetLaneWorldLocation(LanePos3) + Offset * 1.2, GetLaneWorldLocation(OffsetPos) + Offset * 1.2, FLinearColor::Green, 4.0);
			Debug::DrawDebugString(GetLaneWorldLocation(OffsetPos) + Offset * 1.5, "" + Math::Wrap(Delta, -LaneLength * 0.5, LaneLength * 0.5), Scale = 2.0);
		}
	}
#endif	
}

enum EWalkerArenaSide
{
	Front = 0,
	Right = 1,
	Left = 2,
	Rear = 3
}

struct FWalkerArenaRespawnpoints
{
	TArray<ARespawnPoint> Points;

	TArray<FInstigator> Disablers;

	const FName ArenaInstigator = n"WalkerArena";

	void Disable(FInstigator Instigator)
	{
		// Respawn points are enabled as long as _any_ instigator wants them to be enabled, so we need an abstraction layer
		Disablers.Add(Instigator);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
			for (ARespawnPoint Point : Points)
			{
				Point.DisableForPlayer(Player, ArenaInstigator);
				Point.RespawnPriority = ERespawnPointPriority::Normal;
			}
		}
	}

	void Enable(FInstigator Instigator)
	{
		Disablers.Remove(Instigator);

		// Only enable once all disablers have been removed
		if (Disablers.Num() == 0)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				for (ARespawnPoint Point : Points)
				{
					Point.EnableForPlayer(Player, ArenaInstigator);
				}
			}
		}
	}
}

