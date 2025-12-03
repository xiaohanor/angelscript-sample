class USketchbookBowDrawTrajectoryCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USketchbookBowTrajectoryMeshComponent TrajectoryMeshComp;
	USketchbookBowPlayerComponent BowComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TrajectoryMeshComp = USketchbookBowTrajectoryMeshComponent::Get(Player);
        BowComp = USketchbookBowPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BowComp.IsUsingBow())
			return false;

		if(!BowComp.IsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BowComp.IsUsingBow())
			return true;

		if(!BowComp.IsAiming())
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
		TrajectoryMeshComp.ResetMesh();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TrajectoryMeshComp.RecreateMesh(BowComp.AimTrajectorySpline);
	}
};