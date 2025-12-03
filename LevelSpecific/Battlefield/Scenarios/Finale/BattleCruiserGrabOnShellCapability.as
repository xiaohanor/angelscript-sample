class UBattleCruiserGrabOnShellCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BattleCruiserGrabOnShellCapability");
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	ABattleCruiserGrabOnShell Shell;

	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Shell = Cast<ABattleCruiserGrabOnShell>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Shell.bShellActive)
			return false;

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
		Speed = Math::FInterpConstantTo(Speed, Shell.TargetSpeed, DeltaTime, Shell.TargetSpeed / 2.0);
		Shell.ActorLocation += Shell.ActorForwardVector * Speed * DeltaTime;
	}
} 