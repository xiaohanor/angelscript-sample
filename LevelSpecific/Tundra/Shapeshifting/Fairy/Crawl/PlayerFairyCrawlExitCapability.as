class UTundraPlayerFairyCrawlExitCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 75;
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
		if(CrawlPlayerComp.CurrentCrawlSplineActor != nullptr)
			return false;

		if(!CrawlPlayerComp.bIsInCrawl)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CrawlPlayerComp.CurrentCrawlSplineActor != nullptr)
			return true;

		if(ActiveDuration > Settings.ExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CrawlPlayerComp.AnimData.bIsExitingCrawl = true;
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrawlPlayerComp.bIsInCrawl = false;
		CrawlPlayerComp.AnimData.bIsExitingCrawl = false;
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		if(CrawlPlayerComp.PreviousCrawlSplineActor != nullptr)
			CrawlPlayerComp.PreviousCrawlSplineActor.OnExitCrawl.Broadcast();
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
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"FantasyFairyCrawl");
		}
	}
}