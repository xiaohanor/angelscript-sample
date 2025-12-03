class USummitAdultDragonCircleStrafeManagerTempBossFacingPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	const float CameraSplinePosFollowDuration = 2.5;

	ASummitAdultDragonCircleStrafeManager StrafeManager;

	UCameraUserComponent CameraUserComp;

	FHazeAcceleratedVector AccSplineFollowPos;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeManager = Cast<ASummitAdultDragonCircleStrafeManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::Circling)
			return false;

		if(StrafeManager.bTempBossRotation)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::Circling)
			return true;

		if(StrafeManager.bTempBossRotation)
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
		auto Boss = StrafeManager.Boss;

		FVector TargetLoc = Game::Zoe.ViewLocation;
		FVector Dir = (TargetLoc - Boss.ActorLocation).GetSafeNormal();
		Dir = Dir.ConstrainToPlane(FVector::UpVector);
		Boss.ActorRotation = Dir.Rotation();
	}
};