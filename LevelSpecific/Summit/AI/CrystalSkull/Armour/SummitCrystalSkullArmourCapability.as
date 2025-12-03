class USummitCrystalSkullArmourCapability : UHazeCapability
{
	USummitCrystalSkullArmourComponent ArmourComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
		UAcidResponseComponent AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);		
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		ArmourComp.OnAcidHit(Hit);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArmourComp == nullptr)
			return false;
		if (!ArmourComp.ArmourClass.IsValid())
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
		ArmourComp.CreateArmour();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}
