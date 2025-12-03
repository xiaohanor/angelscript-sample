class UMedallionPlayerMergeTimeDilationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player == Game::Zoe)
			return false;
		if (!MedallionComp.bCameraFocusFullyMerged)
			return false;
		if (HighfiveComp.IsHighfiveJumping())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MedallionComp.bCameraFocusFullyMerged)
			return true;
		if (HighfiveComp.IsHighfiveJumping())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Time::SetWorldTimeDilation(0.8);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};