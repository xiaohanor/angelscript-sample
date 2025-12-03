UCLASS(Abstract)
class UTundraPlayerCrackBirdBaseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default BlockExclusionTags.Add(CrackBirdTags::CrackBird);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::TreeGuardian);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkey);

	UBigCrackBirdCarryComponent CarryComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarryComp = UBigCrackBirdCarryComponent::Get(Player);
	}

	const ABigCrackBird GetBird() const
	{
		return CarryComp.GetBird();
	}
};