class UPrisonBossCloneExitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UPrisonBossCloneManagerComponent CloneComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		CloneComp = UPrisonBossCloneManagerComponent::GetOrCreate(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CloneComp.DeleteClones();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ClearCameraSettingsByInstigator(CloneComp);

		UPrisonBossEffectEventHandler::Trigger_CloneExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsExitingClone = false;
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::Clone);

		UPrisonBossEffectEventHandler::Trigger_CloneFinished(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}