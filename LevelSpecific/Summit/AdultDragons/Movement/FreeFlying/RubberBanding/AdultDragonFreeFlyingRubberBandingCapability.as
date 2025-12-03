class UAdultDragonFreeFlyingRubberBandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonFreeFlyingComponent FlyingComp;
	UAdultDragonFreeFlyingComponent OtherFlyingComp;
	UAdultDragonSplineFollowRubberBandingSettings RubberBandSettings;

	UAdultDragonSplineRubberBandSyncPointComponent CurrentSyncPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RubberBandSettings = UAdultDragonSplineFollowRubberBandingSettings::GetSettings(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		FlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);
		OtherFlyingComp = UAdultDragonFreeFlyingComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (FlyingComp == nullptr)
			FlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);

		if (OtherFlyingComp == nullptr)
			OtherFlyingComp = UAdultDragonFreeFlyingComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FlyingComp.RubberBandingMoveSpeedMultiplier = 1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto SplinePos = FlyingComp.RubberBandSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation, true);
		auto OtherSplinePos = FlyingComp.RubberBandSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorCenterLocation, true);
		
		if (FlyingComp.RubberBandSpline.Spline != SplinePos.CurrentSpline)
		{
			FlyingComp.RubberBandSpline = Cast<AAdultDragonFreeFlyingRubberBandSpline>(SplinePos.CurrentSpline.Owner);
		}

		if (OtherFlyingComp.RubberBandSpline.Spline != OtherSplinePos.CurrentSpline)
		{
			OtherFlyingComp.RubberBandSpline = Cast<AAdultDragonFreeFlyingRubberBandSpline>(OtherSplinePos.CurrentSpline.Owner);
		}

		float DistAlongSpline = SplinePos.CurrentSplineDistance;
		float OtherPlayerDistAlongSpline = OtherSplinePos.CurrentSplineDistance;

		auto PlayerSyncPoint = FlyingComp.RubberBandSpline.GetSyncPointAtDistanceAlongSpline(DistAlongSpline);
		auto OtherPlayerSyncPoint = OtherFlyingComp.RubberBandSpline.GetSyncPointAtDistanceAlongSpline(OtherPlayerDistAlongSpline);
		CurrentSyncPoint = PlayerSyncPoint;

		if (Player.OtherPlayer.IsPlayerDead() || Player.OtherPlayer.IsPlayerRespawning())
		{
			FlyingComp.RubberBandingMoveSpeedMultiplier = 1;
		}
		else
		{
			if (PlayerSyncPoint != OtherPlayerSyncPoint)
			{
				float TargetRubberBandMultiplier = GetDifferentTargetsRubberBandMultiplier(PlayerSyncPoint, OtherPlayerSyncPoint);
				FlyingComp.RubberBandingMoveSpeedMultiplier = Math::FInterpConstantTo(FlyingComp.RubberBandingMoveSpeedMultiplier, TargetRubberBandMultiplier, DeltaTime, 1);
			}
			else
			{
				FlyingComp.RubberBandingMoveSpeedMultiplier = GetSameTargetLocationRubberBandMultiplier(PlayerSyncPoint);
			}
		}

	}

	float GetDifferentTargetsRubberBandMultiplier(const UAdultDragonSplineRubberBandSyncPointComponent&in PlayerSyncPoint, const UAdultDragonSplineRubberBandSyncPointComponent&in OtherPlayerSyncPoint)
	{
		Player.ClearSettingsByInstigator(this);
		AHazePlayerCharacter CurrentAheadPlayer;
		if (FlyingComp.RubberBandSpline.IsSplineComponentAheadOfOtherSplineComponent(PlayerSyncPoint, OtherPlayerSyncPoint))
		{
			CurrentAheadPlayer = Player;
			Player.ApplySettings(PlayerSyncPoint.RubberBandSettings, this, EHazeSettingsPriority::Script);
		}
		else
		{
			CurrentAheadPlayer = Player.OtherPlayer;
			Player.ApplySettings(OtherPlayerSyncPoint.RubberBandSettings, this, EHazeSettingsPriority::Script);
		}

		bool bIsBehind = CurrentAheadPlayer != Player;
		float RubberBandingMoveSpeedMultiplier = 1;
		if (bIsBehind)
			RubberBandingMoveSpeedMultiplier = RubberBandSettings.MaxBehindSpeedMultiplier;
		else
			RubberBandingMoveSpeedMultiplier = RubberBandSettings.MaxAHeadSpeedMultiplier;

		return RubberBandingMoveSpeedMultiplier;
	}

	float GetSameTargetLocationRubberBandMultiplier(const UAdultDragonSplineRubberBandSyncPointComponent&in PlayerSyncPoint)
	{
		Player.ClearSettingsByInstigator(this);
		Player.ApplySettings(PlayerSyncPoint.RubberBandSettings, this, EHazeSettingsPriority::Script);
		AHazePlayerCharacter WantedAheadPlayer = Game::GetPlayer(RubberBandSettings.PreferredAheadPlayer);

		float DistanceToSyncPoint = Player.ActorCenterLocation.Distance(PlayerSyncPoint.WorldLocation);
		float OtherPlayerDistanceToSyncPoint = Player.OtherPlayer.ActorCenterLocation.Distance(PlayerSyncPoint.WorldLocation);
		float RubberBandDistance = DistanceToSyncPoint - OtherPlayerDistanceToSyncPoint;
		float DistanceBetweenPlayers = Player.GetDistanceTo(Player.OtherPlayer);

		float RubberBandingMoveSpeedMultiplier = FlyingComp.RubberBandingMoveSpeedMultiplier;

		if (DistanceBetweenPlayers < RubberBandSettings.IdealPlayerDistance)
		{
			// maintain distance between players with preferred player in front
			bool bWantsToBeAhead = WantedAheadPlayer == Player;
			if (bWantsToBeAhead)
			{
				RubberBandingMoveSpeedMultiplier = Math::GetMappedRangeValueClamped(
					FVector2D(0, RubberBandSettings.IdealPlayerDistance),
					FVector2D(RubberBandSettings.MaxBehindSpeedMultiplier, 1.0),
					DistanceBetweenPlayers);
			}
			else
			{
				RubberBandingMoveSpeedMultiplier = Math::GetMappedRangeValueClamped(
					FVector2D(0, RubberBandSettings.IdealPlayerDistance),
					FVector2D(RubberBandSettings.MaxAHeadSpeedMultiplier, 1.0),
					DistanceBetweenPlayers);
			}
		}
		else
		{
			// if we are closer to the syncpoint than the other player, then our RubberBandDistance is negative
			if (RubberBandDistance > RubberBandSettings.MinDistance)
			{
				RubberBandingMoveSpeedMultiplier = Math::GetMappedRangeValueClamped(
					FVector2D(RubberBandSettings.MinDistance, RubberBandSettings.MaxDistance),
					FVector2D(1.0, RubberBandSettings.MaxBehindSpeedMultiplier),
					RubberBandDistance);
			}
			else if (RubberBandDistance < -RubberBandSettings.MinDistance)
			{
				RubberBandingMoveSpeedMultiplier = Math::GetMappedRangeValueClamped(
					FVector2D(-RubberBandSettings.MinDistance, -RubberBandSettings.MaxDistance),
					FVector2D(1.0, RubberBandSettings.MaxAHeadSpeedMultiplier),
					RubberBandDistance);
			}
		}

		return RubberBandingMoveSpeedMultiplier;
	}
};
