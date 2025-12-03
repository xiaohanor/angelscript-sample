class USketchbookBossArenaMoveCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASketchbookBossFightManager BossFight;
	AHazeCameraActor Camera;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossFight = Cast<ASketchbookBossFightManager>(Owner);
		Camera = BossFight.BossCamera;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BossFight.bUpdateCamera)
			return false;

		if(Camera == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Camera.ActorLocation.Distance(BossFight.TargetCameraLocation) <= KINDA_SMALL_NUMBER)
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
		Camera.SetActorLocation(BossFight.TargetCameraLocation);
		BossFight.bUpdateCamera = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewCameraLocation = Math::VInterpTo(Camera.ActorLocation, BossFight.TargetCameraLocation, DeltaTime, 1);
		Camera.SetActorLocation(NewCameraLocation);
	}
};