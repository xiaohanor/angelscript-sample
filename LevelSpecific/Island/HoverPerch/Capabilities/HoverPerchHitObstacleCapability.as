class UHoverPerchHitObstacleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHoverPerchActor HoverPerch;
	UHoverPerchMovementComponent MoveComp;

	AIslandWalkerGrindObstacle CurrentObstacle;
	FVector ObstacleStartLocation;
	bool bInstantKill;
	USceneComponent PreviousAttachment;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverPerch = Cast<AHoverPerchActor>(Owner);
		MoveComp = UHoverPerchMovementComponent::Get(HoverPerch);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchHitObstacleActivatedParams& Params) const
	{
		if(HoverPerch.PlayerLocker == nullptr)
			return false;

		TListedActors<AIslandWalkerGrindObstacle> ListedObstacles;

		for(AIslandWalkerGrindObstacle Obstacle : ListedObstacles)
		{
			if(!Obstacle.bIsActive)
				continue;

			if(IsIntersectingObstacle(Obstacle))
			{
				Params.CurrentObstacle = Obstacle;
				Params.bInstantKill = Obstacle.HoverPerchesMovingObstacle.Num() > 0;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ObstacleStartLocation.DistSquared(CurrentObstacle.DestinationComp.WorldLocation) >= Math::Square(CurrentObstacle.MaxDistanceBeforeDestruction))
			return true;

		if(bInstantKill)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchHitObstacleActivatedParams Params)
	{
		bInstantKill = Params.bInstantKill;
		CurrentObstacle = Params.CurrentObstacle;
		CurrentObstacle.HoverPerchesMovingObstacle.Add(HoverPerch);

		HoverPerch.InstigatedGrindSpeedMultiplier.ApplyMultiplier(HoverPerch.GrindSpeedMultiplierWhenHittingObstacle, this);
		ObstacleStartLocation = CurrentObstacle.DestinationComp.WorldLocation;
		PreviousAttachment = CurrentObstacle.DestinationComp.AttachParent;

		CurrentObstacle.DestinationComp.AttachToComponent(HoverPerch.RootComponent, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentObstacle.OnClear(HoverPerch.PlayerLocker);
		CurrentObstacle.HoverPerchesMovingObstacle.RemoveSingleSwap(HoverPerch);
		HoverPerch.PostDestroyObstacleBoostDurationRemaining = HoverPerch.GrindSpeedMultiplierAfterDestroyedObstacleDuration;

		HoverPerch.InstigatedGrindSpeedMultiplier.ClearMultiplier(this);

		CurrentObstacle.DestinationComp.AttachToComponent(PreviousAttachment, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	bool IsIntersectingObstacle(AIslandWalkerGrindObstacle Obstacle) const
	{
		FBox CubeBounds = Obstacle.MainCube.GetComponentLocalBoundingBox();
		FVector LocalPerchLocation = Obstacle.MainCube.WorldTransform.InverseTransformPosition(HoverPerch.ActorLocation);
		float SphereRadius = HoverPerch.SphereCollisionComp.SphereRadius / Obstacle.MainCube.WorldScale.X;
		return Math::SphereAABBIntersection(LocalPerchLocation, Math::Square(SphereRadius), CubeBounds);
	}
}

struct FHoverPerchHitObstacleActivatedParams
{
	AIslandWalkerGrindObstacle CurrentObstacle;
	bool bInstantKill = false;
}