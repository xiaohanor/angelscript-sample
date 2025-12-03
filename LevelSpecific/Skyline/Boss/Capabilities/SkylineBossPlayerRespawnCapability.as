class USkylineBossPlayerRespawnCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBoss);

	TPerPlayer<UPlayerRespawnComponent> PlayerRespawnComp;

	ASkylineBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBoss>(Owner);

		for (auto Player : Game::Players)
			PlayerRespawnComp[Player] = UPlayerRespawnComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.IsActorDisabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto RespawnComp : PlayerRespawnComp)
		{
			FOnRespawnOverride Delegate;
			Delegate.BindUFunction(this, n"GetRespawnPoint");
			RespawnComp.ApplyRespawnOverrideDelegate(this, Delegate, EInstigatePriority::High);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto RespawnComp : PlayerRespawnComp)
		{
			RespawnComp.ClearRespawnOverride(this);
		}
	}

	UFUNCTION()
	private bool GetRespawnPoint(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		if(Boss.RespawnSpline == nullptr)
			return false;

		FSplinePosition SplinePosition = Boss.RespawnSpline.Spline.GetClosestSplinePositionToWorldLocation(Boss.ActorLocation);
		
		// Move half the length of the spline to end up on the other side
		SplinePosition.Move(Boss.RespawnSpline.Spline.SplineLength * 0.5);
		const FTransform SplineTransform = SplinePosition.WorldTransform;

		const FVector ToBoss = Boss.ActorLocation - SplineTransform.Location;
		FQuat ToBossRotation = FQuat::MakeFromZX(FVector::UpVector, ToBoss);
		OutLocation.RespawnTransform = FTransform(ToBossRotation, SplineTransform.Location);
		OutLocation.bRecalculateOnRespawnTriggered = false;
		return true;

/*
		FRespawnLocation RespawnLocation;

		TListedActors<ARespawnPoint> AllRespawnPoints;

		float ClosestDistance = MAX_flt;
		ERespawnPointPriority Priority = ERespawnPointPriority::Lowest;
		ARespawnPoint ClosestRespawnPoint = nullptr;
		FTransform ClosestPosition;

		FVector PlayerLocation = Player.ActorLocation;

		for (ARespawnPoint RespawnPoint : AllRespawnPoints)
		{
			if (int(RespawnPoint.RespawnPriority) < int(Priority))
				continue;

			if (!RespawnPoint.IsEnabledForPlayer(Player))
				continue;
			if (!RespawnPoint.IsValidToRespawn(Player))
				continue;

			if (int(RespawnPoint.RespawnPriority) > int(Priority))
			{
				// Higher priority checkpoint, reset the current
				Priority = RespawnPoint.RespawnPriority;
				ClosestRespawnPoint = nullptr;
				ClosestDistance = MAX_flt;
			}

			FTransform Position = RespawnPoint.GetPositionForPlayer(Player);
			float Distance = Position.GetLocation().DistSquared(PlayerLocation);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestRespawnPoint = RespawnPoint;
				ClosestPosition = Position;
			}
		}

		if (ClosestRespawnPoint != nullptr)
		{
			RespawnLocation.RespawnPoint = ClosestRespawnPoint;
			RespawnLocation.RespawnTransform = ClosestRespawnPoint.GetPositionForPlayer(Player);
		}

		Debug::DrawDebugPoint(ClosestRespawnPoint.GetPositionForPlayer(Player).Location, 200.0, FLinearColor::Green, 5.0);

		const FVector ToBoss = Boss.ActorLocation - ClosestRespawnPoint.GetPositionForPlayer(Player).Location;

		Debug::DrawDebugLine(ClosestRespawnPoint.GetPositionForPlayer(Player).Location, ClosestRespawnPoint.GetPositionForPlayer(Player).Location + ToBoss, FLinearColor::Green, 50.0, 5.0);

		FQuat ToBossRotation = FQuat::MakeFromZX(FVector::UpVector, ToBoss);
		RespawnLocation.RespawnTransform.Rotation = ToBossRotation;
		RespawnLocation.bRecalculateOnRespawnTriggered = false;

		OutLocation = RespawnLocation;

		return true;
*/
	}
}