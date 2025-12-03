event void OnStartMedallionFlyingSignature();
event void OnStopMedallionFlyingSignature();
event void OnMergeSignature();


namespace MedallionPlayer
{
	UFUNCTION(BlueprintPure, DisplayName = "Get Player Medallion Component", Category = "Sanctuary|Hydra")
	UMedallionPlayerComponent BP_GetPlayerMedallionComponent(AHazePlayerCharacter Player)
	{
		UMedallionPlayerComponent Comp = UMedallionPlayerComponent::GetOrCreate(Player);
		return Comp;
	}
}

class UMedallionPlayerComponent : UActorComponent
{
	private bool bIsMedallionCoopFlying = false;
	private UMedallionPlayerGloryKillComponent GloryKillComp;
	private UMedallionPlayerReferencesComponent RefsComp;
	private AHazePlayerCharacter Player;

	float HighfiveZoomAlpha = 1.0;

	float ProjectionOffsetAlpha = 0.0;
	float AddedHorizontalDist = 0.0;
	bool bCameraFocusFullyMerged = false;

	AMedallionMedallionActor MedallionActor;

	bool bShowMioInsideMedallion = false;
	bool bMioMedallionChill = false;
	AActor InsideZoeFakeMedallion = nullptr;
	bool bAllowCutsceneHover = false;
	bool bForceHidden = false;

	bool bCutsceneAllowShowTether = false;
	bool bCutsceneAllowFlying = false;
	bool bHasMergedFocus = false;

	private FHazeEasedVector EasedPlayerLocation;
	bool bPlayerWasDead = false;
	private FVector CachedRespawnLocation;

	UPROPERTY()
	OnStartMedallionFlyingSignature OnStartMedallionFlying;

	UPROPERTY()
	OnStopMedallionFlyingSignature OnStopMedallionFlying;

	UPROPERTY()
	OnMergeSignature OnFocusFullyMerged;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	bool IsMedallionCoopFlying() const
	{
		return bIsMedallionCoopFlying;
	}

	bool IsFlyingNotReturning() const
	{
		if (GloryKillComp.GloryKillState == EMedallionGloryKillState::Return)
			return false;
		return bIsMedallionCoopFlying;
	}

	void StartMedallionFlying()
	{
		bIsMedallionCoopFlying = true;
		MedallionActor.AddActorDisable(this);
		OnStartMedallionFlying.Broadcast();
	}

	void StopMedallionFlying()
	{
		bIsMedallionCoopFlying = false;
		MedallionActor.RemoveActorDisable(this);
		OnStopMedallionFlying.Broadcast();
	}

	FVector GetPlayerLerpedRespawnLocation(float DeltaTime)
	{
		if (Player.IsPlayerDead() && bHasMergedFocus)
		{
			FRespawnLocation RespawnLocation;
			if (GetMergeRespawnLocation(Player, RespawnLocation))
			{
				if (!bPlayerWasDead)
				{
					EasedPlayerLocation.ForceResetProgress();
					bPlayerWasDead = true;
					CachedRespawnLocation = RespawnLocation.RespawnRelativeTo.WorldLocation;
				}
				EasedPlayerLocation.EaseTo(Player.ActorCenterLocation, CachedRespawnLocation, 5.0, DeltaTime, EEasing::EaseInOut);
				return EasedPlayerLocation.GetValue();
			}
		}
		bPlayerWasDead = false;
		return Player.ActorCenterLocation;
	}

	UFUNCTION()
	bool GetMergeRespawnLocation(AHazePlayerCharacter RespawningPlayer, FRespawnLocation& OutLocation) const
	{
		TListedActors<ARespawnPoint> ListedRespawnPoints;
		TArray<ARespawnPoint> RespawnPoints = ListedRespawnPoints.GetArray();

		float Signwards = Player.IsMio() ? -1.0 : 1.0;
		float OtherPlayerSplineDist = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);
		float OurPlayerSplineDist = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		float SplineDistBehindOtherPlayer = OtherPlayerSplineDist + Signwards * MedallionConstants::Merge::MergeRespawnDistanceFromOtherPlayer;
		float MostBackwardsDistance = SplineDistBehindOtherPlayer; //Player.IsMio() ? Math::Min(SplineDistBehindOtherPlayer, OurPlayerSplineDist) : Math::Max(SplineDistBehindOtherPlayer, OurPlayerSplineDist); // Hannes only wants SplineDistBehindOtherPlayer
		
		FVector FutureLocation = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetWorldLocationAtSplineDistance(MostBackwardsDistance);
		if (SanctuaryMedallionHydraDevToggles::Draw::MergeRespawnPoints.IsEnabled())
		{
			Debug::DrawDebugSphere(FutureLocation, 50, 12, Player.GetPlayerUIColor(), bDrawInForeground = true);
			Debug::DrawDebugString(FutureLocation, Player.GetName() + " Target Respawn Location");
		}
		
		ARespawnPoint BestRespawnPoint = FindRespawnPoint(RespawnPoints, MostBackwardsDistance, FutureLocation, true);
		if (BestRespawnPoint == nullptr) // can happen if players are on the edge of sidescroller
			BestRespawnPoint = FindRespawnPoint(RespawnPoints, MostBackwardsDistance, FutureLocation, true);

		if (BestRespawnPoint != nullptr)
		{
			OutLocation.RespawnPoint = BestRespawnPoint;
			OutLocation.RespawnRelativeTo = BestRespawnPoint.RootComponent;
			OutLocation.RespawnTransform = BestRespawnPoint.GetRelativePositionForPlayer(Player);

			if (SanctuaryMedallionHydraDevToggles::Draw::MergeRespawnPoints.IsEnabled())
			{
				Debug::DrawDebugSphere(BestRespawnPoint.ActorCenterLocation, 100, 12, Player.GetPlayerUIColor());
				Debug::DrawDebugString(BestRespawnPoint.ActorCenterLocation + FVector::UpVector * 100, Player.GetName() + " Respawn", Player.GetPlayerUIColor());
				Debug::DrawDebugArrow(FutureLocation, BestRespawnPoint.ActorCenterLocation, LineColor = Player.GetPlayerUIColor(), bDrawInForeground = true);
			}
			return true;
		}

		return false;
	}

	private ARespawnPoint FindRespawnPoint(TArray<ARespawnPoint> RespawnPoints, float MostBackwardsDistance, FVector FutureLocation, bool bAllowIncorrectWay) const
	{
		ARespawnPoint BestRespawnPoint = nullptr;
		float BestDistance = BIG_NUMBER;
		bool bFoundNull = false;

		for (int iRespawn = 0; iRespawn < RespawnPoints.Num(); iRespawn++)
		{
			ARespawnPoint RespawnPoint = RespawnPoints[iRespawn];
			if (RespawnPoint == nullptr)
			{
				bFoundNull = true;
				continue;
			}

			float PlayerDiff = FutureLocation.Distance(Player.ActorLocation);
			if (PlayerDiff < 1000 && SanctuaryMedallionHydraDevToggles::Draw::MergeRespawnPoints.IsEnabled())
			{
				Debug::DrawDebugSphere(RespawnPoint.ActorCenterLocation, 50, 12, RespawnPoint.IsEnabledForPlayer(Player) ? ColorDebug::White : ColorDebug::Gray, bDrawInForeground = true);
			}

			// if (!RespawnPoint.IsEnabledForPlayer(Player))
			// 	continue;

			bool bIsCorrectWay = bAllowIncorrectWay;
			if (!bIsCorrectWay)
			{
				float RespawnPointSplineDist = RefsComp.Refs.SideScrollerSplineLocker.Spline.GetClosestSplineDistanceToWorldLocation(RespawnPoint.ActorCenterLocation);
				bIsCorrectWay = Player.IsMio() ? RespawnPointSplineDist < MostBackwardsDistance : RespawnPointSplineDist > MostBackwardsDistance;
			}
			FVector Diff = RespawnPoint.ActorCenterLocation - FutureLocation;
			float Distance = Diff.Size();
			if (bIsCorrectWay && Distance < BestDistance)
			{
				BestRespawnPoint = RespawnPoint;
				BestDistance = Distance;
			}

			if (SanctuaryMedallionHydraDevToggles::Draw::MergeRespawnPoints.IsEnabled())
			{
				Debug::DrawDebugSphere(RespawnPoint.ActorCenterLocation, 50, 12, ColorDebug::Gray, bDrawInForeground = true);
				Debug::DrawDebugString(RespawnPoint.ActorCenterLocation, "" + RespawnPoint.ActorNameOrLabel);
				FLinearColor WashedOutColor = Math::Lerp(Player.GetPlayerUIColor(), ColorDebug::Gray, 0.8);
				Debug::DrawDebugLine(FutureLocation, RespawnPoint.ActorCenterLocation, WashedOutColor, bDrawInForeground = true);
				Debug::DrawDebugString(FutureLocation + Diff - Diff.GetSafeNormal() * 200, "" + Distance);
			}
		}
		return BestRespawnPoint;
	}
};