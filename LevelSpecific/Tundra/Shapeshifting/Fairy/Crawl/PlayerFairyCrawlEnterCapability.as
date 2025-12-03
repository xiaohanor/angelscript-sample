class UTundraPlayerFairyCrawlEnterCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 50;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerFairyCrawlComponent CrawlPlayerComp;
	UTundraPlayerFairyCrawlSettings Settings;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	FTransform OriginalTransform;

	bool bMoveDone = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrawlPlayerComp = UTundraPlayerFairyCrawlComponent::GetOrCreate(Player);
		Settings = UTundraPlayerFairyCrawlSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CrawlPlayerComp.bIsInCrawl)
			return false;

		if(CrawlPlayerComp.CurrentCrawlSplineActor == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerCrawlEnterDeactivatedParams& Params) const
	{
		if(CrawlPlayerComp.CurrentCrawlSplineActor == nullptr)
			return true;

		if(bMoveDone)
		{
			Params.bShouldEnterCrawl = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(CrawlPlayerComp.CurrentCrawlSplineActor.CameraToActivate != nullptr)
		{
			Player.ActivateCamera(CrawlPlayerComp.CurrentCrawlSplineActor.CameraToActivate, Settings.EnterDuration, CrawlPlayerComp);
			CrawlPlayerComp.CurrentActiveCameraActor = CrawlPlayerComp.CurrentCrawlSplineActor.CameraToActivate;
		}
		
		OriginalTransform = Player.ActorTransform;
		bMoveDone = false;
		CrawlPlayerComp.CurrentSplinePosition = CrawlPlayerComp.CurrentCrawlSplineActor.GetInitialSplinePosition(CrawlPlayerComp.bReversed);

		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		CrawlPlayerComp.CurrentCrawlSplineActor.OnEnterCrawl.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerCrawlEnterDeactivatedParams Params)
	{
		if(Params.bShouldEnterCrawl)
			CrawlPlayerComp.bIsInCrawl = true;
		else if(CrawlPlayerComp.CurrentActiveCameraActor != nullptr)
		{
			Player.DeactivateCamera(CrawlPlayerComp.CurrentActiveCameraActor, Settings.ExitDuration);
			CrawlPlayerComp.CurrentActiveCameraActor = nullptr;
		}

		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float EasedAlpha = Math::EaseInOut(0.0, 1.0, Math::Saturate(ActiveDuration / Settings.EnterDuration), 2.0);
				if(Math::IsNearlyEqual(EasedAlpha, 1.0))
				{
					EasedAlpha = 1.0;
					bMoveDone = true;
				}

				FTransform FirstSplineTransform = CrawlPlayerComp.CurrentSplinePosition.WorldTransform;
				
				FVector NewLocation = Math::Lerp(OriginalTransform.Location, FirstSplineTransform.Location, EasedAlpha);
				FQuat NewRotation = FQuat::Slerp(OriginalTransform.Rotation, FirstSplineTransform.Rotation, EasedAlpha);
				Movement.AddDelta(NewLocation - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.SetRotation(NewRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"FantasyFairyCrawl");
		}
	}
}

struct FTundraPlayerCrawlEnterDeactivatedParams
{
	bool bShouldEnterCrawl = false;
}