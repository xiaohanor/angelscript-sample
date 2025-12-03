class UTeenDragonAcidPuddleTrailCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	UTeenDragonAcidPuddleContainerComponent PuddleComponent;
	UPlayerMovementComponent MoveComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PuddleComponent = UTeenDragonAcidPuddleContainerComponent::Get(Player);
		MoveComponent = UPlayerMovementComponent::Get(Player);
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
	void OnDeactivated()
	{
		PuddleComponent.CollectedAcidAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		// Decrease the collected puddle pool amount
		const float LifeTime = 10;
		PuddleComponent.CollectedAcidAlpha = Math::FInterpConstantTo(PuddleComponent.CollectedAcidAlpha, 0, DeltaTime, 1 / LifeTime);

		// Increase the pool amount if we are inside a pool
		if(PuddleComponent.OverlappingPuddles.Num() > 0 && MoveComponent.IsOnAnyGround())
		{
			PuddleComponent.CollectedAcidAlpha = Math::FInterpConstantTo(PuddleComponent.CollectedAcidAlpha, 1, DeltaTime, 10);
		}	
	}

};