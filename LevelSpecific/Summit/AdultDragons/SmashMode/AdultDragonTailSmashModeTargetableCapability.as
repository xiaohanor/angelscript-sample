class UAdultDragonTailSmashModeTargetableCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonTailSmashModeComponent SmashModeComp;

	UAdultDragonTailSmashModeSettings SmashSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SmashModeComp = UAdultDragonTailSmashModeComponent::Get(Player);

		SmashSettings = UAdultDragonTailSmashModeSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SmashModeComp.bSmashModeActive)
			return false;
		
		auto PrimaryTarget = 
			PlayerTargetablesComponent.GetPrimaryTarget(UAdultDragonTailSmashModeTargetableComponent);
		
		if(PrimaryTarget == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SmashModeComp.bSmashModeActive)
			return true;

		auto PrimaryTarget = 
			PlayerTargetablesComponent.GetPrimaryTarget(UAdultDragonTailSmashModeTargetableComponent);
		
		if(PrimaryTarget == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto PrimaryTarget = 
			PlayerTargetablesComponent.GetPrimaryTarget(UAdultDragonTailSmashModeTargetableComponent);

		if(PrimaryTarget == nullptr)
			return;

		auto SmashModeTarget = Cast<UAdultDragonTailSmashModeTargetableComponent>(PrimaryTarget);
		
		FVector TowardsCenter = PrimaryTarget.WorldLocation - Player.ActorLocation;
		FQuat RotToCenter = FRotator::MakeFromX(TowardsCenter).Quaternion();

		FQuat CurrentRotation = Player.ActorRotation.Quaternion();

		FQuat InfluencedRotation = Math::QInterpTo(CurrentRotation, RotToCenter, DeltaTime, SmashModeTarget.InterpSpeed);
		Player.SetActorRotation(InfluencedRotation);
		DragonComp.AccRotation.SnapTo(InfluencedRotation.Rotator(), DragonComp.AccRotation.Velocity);
	}
};