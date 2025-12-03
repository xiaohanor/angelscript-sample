class UMedallionPlayerMergeHighfiveTimedilationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	FHazeAcceleratedFloat AccTimeDilation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HighfiveComp.IsHighfiveJumping())
			return false;
		if (Player.IsZoe()) // only one should dilate
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{ 
		if (HighfiveComp.IsInHighfiveFail())
			return false;
		if (!HighfiveComp.IsHighfiveJumping())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//AccTimeDilation.SnapTo(MedallionConstants::Highfive::HighfiveTimedilation);
		AccTimeDilation.SnapTo(0.5);
		Time::SetWorldTimeDilation(AccTimeDilation.Value);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Time::SetWorldTimeDilation(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsMio())
		{
			float Target = HighfiveComp.CanCompleteHighfive() ? MedallionConstants::Highfive::HighfiveTimedilation : 0.5;
			if (HighfiveComp.WillProbablyCompleteHighfive())
				Target = 1.0;
			AccTimeDilation.AccelerateTo(Target, 1.0, DeltaTime);
			Time::SetWorldTimeDilation(AccTimeDilation.Value);
		}
	}
};