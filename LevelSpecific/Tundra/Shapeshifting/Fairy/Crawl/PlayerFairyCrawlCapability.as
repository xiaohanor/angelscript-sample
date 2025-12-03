class UTundraPlayerFairyCrawlCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerFairyCrawlComponent CrawlPlayerComp;
	UTundraPlayerFairyCrawlSettings Settings;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

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
		if(CrawlPlayerComp.CurrentCrawlSplineActor == nullptr)
			return false;

		if(!CrawlPlayerComp.bIsInCrawl)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CrawlPlayerComp.CurrentCrawlSplineActor == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(CrawlPlayerComp.CurrentActiveCameraActor != nullptr)
		{
			Player.DeactivateCamera(CrawlPlayerComp.CurrentActiveCameraActor, Settings.ExitDuration);
			CrawlPlayerComp.CurrentActiveCameraActor = nullptr;
		}

		if(!IsEnabled())
		{
			CrawlPlayerComp.CurrentCrawlSplineActor = nullptr;
			CrawlPlayerComp.bIsInCrawl = false;
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
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				
				float Input = CrawlPlayerComp.CurrentSplinePosition.WorldRotation.ForwardVector.DotProduct(MoveComp.MovementInput);
				float Delta = 0.0;
				if(Input > KINDA_SMALL_NUMBER)
				{
					float Speed = Math::Lerp(Settings.MinCrawlSpeed, Settings.MaxCrawlSpeed, Input);
					Delta = Speed * DeltaTime;
				}
				
				CrawlPlayerComp.CurrentSplinePosition.Move(Delta);
				Movement.AddDelta(CrawlPlayerComp.CurrentSplinePosition.WorldLocation - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
				Movement.SetRotation(CrawlPlayerComp.CurrentSplinePosition.WorldRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"FantasyFairyCrawl");
		}
	}
}