class UDentistToothPossessCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UDentistToothPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
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
		PlayerComp.SpawnAndAttachTooth();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};