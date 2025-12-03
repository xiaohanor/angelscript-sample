class UMoonGuardianAnimationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMoonGuardianCat GuardianCat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GuardianCat = Cast<AMoonGuardianCat>(Owner);
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
		//GuardianCat.Mesh.RequestLocomotion(n"MoonGuardian", this);
	}
};