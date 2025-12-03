class UBasicAIRequestOverrideFeatureCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UBasicAIAnimationComponent AnimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AnimComp.OverrideFeatureTag.IsNone())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AnimComp.OverrideFeatureTag.IsNone())
			return true;

		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(AnimComp.CharacterMesh.CanRequestOverrideFeature())
			AnimComp.CharacterMesh.RequestOverrideFeature(AnimComp.OverrideFeatureTag, this);
	}
}