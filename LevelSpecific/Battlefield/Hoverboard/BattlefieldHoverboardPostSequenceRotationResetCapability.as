class UBattlefieldHoverboardPostSequenceRotationResetCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 10;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	UBattlefieldHoverboardComponent HoverboardComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.bIsControlledByCutscene)
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
		Player.ResetMovement(false, FVector::UpVector);
		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.AccRotation.SnapTo(HoverboardComp.WantedRotation);
		HoverboardComp.NudgeWantedRotation = FRotator::ZeroRotator;
	}
};