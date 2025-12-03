class UCentipedeBiteVisualsCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeBite);
	default CapabilityTags.Add(n"BlockedWhileDead");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerTargetablesComponent TargetablesComponent;
	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent BiteComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		BiteComponent = UCentipedeBiteComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BiteComponent.InRangeFraction = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Swing takes precedence, I dunno...
		UCentipedeSwingPointComponent TargetedSwingComponent = TargetablesComponent.GetPrimaryTarget(UCentipedeSwingPointComponent);
		if (TargetedSwingComponent != nullptr)
		{
			float DistanceToSwingComponent = Player.ActorLocation.Distance(TargetedSwingComponent.WorldLocation);
			BiteComponent.InRangeFraction = Math::Saturate(DistanceToSwingComponent / TargetedSwingComponent.ActivationRange);

			return;
		}

		UCentipedeBiteResponseComponent TargetedBiteComponent = TargetablesComponent.GetPrimaryTarget(UCentipedeBiteResponseComponent);
		if (TargetedBiteComponent != nullptr)
		{
			float DistanceToBiteComponent = Player.ActorLocation.Distance(TargetedBiteComponent.WorldLocation);
			BiteComponent.InRangeFraction = Math::Saturate(DistanceToBiteComponent / TargetedBiteComponent.PlayerRange);
		}
		else
		{
			BiteComponent.InRangeFraction = 0.0;
		}
	}
}