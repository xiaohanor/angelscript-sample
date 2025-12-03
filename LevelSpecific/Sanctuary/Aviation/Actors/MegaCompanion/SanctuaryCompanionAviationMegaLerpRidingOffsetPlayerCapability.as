class USanctuaryCompanionAviationMegaCompanionLerpRidingOffsetPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::MegaCompanion);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionMegaCompanionPlayerComponent PlayerComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComponent.bIsRiding)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PlayerComponent.bIsRiding && PlayerComponent.AccCompanionRidingOffset.Value.IsNearlyZero())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetRelative = PlayerComponent.bIsRiding ? PlayerComponent.CompanionRidingOffset : FVector::ZeroVector;
		PlayerComponent.AccCompanionRidingOffset.AccelerateTo(TargetRelative, 0.1, DeltaTime);
		PlayerComponent.MegaCompanion.SkeletalMesh.SetRelativeLocation(PlayerComponent.AccCompanionRidingOffset.Value);
	}
};