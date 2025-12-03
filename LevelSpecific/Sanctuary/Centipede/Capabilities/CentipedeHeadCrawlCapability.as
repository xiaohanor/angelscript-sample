class UCentipedeHeadCrawlCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CentipedeTags::CentipedeCrawl);
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		if (!Player.IsAnyCapabilityActive(CentipedeTags::CentipedeGroundMovement))
			return false;

		if (!IsStandingOnCrawlableActor())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (!Player.IsAnyCapabilityActive(CentipedeTags::CentipedeGroundMovement))
			return true;

		if (!CentipedeComponent.IsCrawling())
			return true;

		// Eman TODO: SCARY! Place proper constraints or players will fall!
		if (!IsStandingOnCrawlableActor())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AddMovementAlignsWithGroundContact(this, false, EInstigatePriority::High);

		FMovementSettingsValue StepSettings;
		StepSettings.Type = EMovementSettingsValueType::CollisionShapePercentage;
		StepSettings.Value = 0.5;

		UMovementSteppingSettings::SetStepUpSize(Player, StepSettings, this);
		UMovementSteppingSettings::SetStepDownSize(Player, StepSettings, this);

		CentipedeComponent.bCrawling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveMovementAlignsWithGroundContact(this);

		UMovementSteppingSettings::ClearStepUpSize(Player, this);
		UMovementSteppingSettings::ClearStepDownSize(Player, this);

		CentipedeComponent.bCrawling = false;
	}

	bool IsStandingOnCrawlableActor() const
	{
		if (MovementComponent.GroundContact.Actor != nullptr)
		{
			UCentipedeCrawlableComponent CrawlableComponent = UCentipedeCrawlableComponent::Get(MovementComponent.GroundContact.Actor);
			if (CrawlableComponent != nullptr)
				return true;
		}

		return false;
	}
}