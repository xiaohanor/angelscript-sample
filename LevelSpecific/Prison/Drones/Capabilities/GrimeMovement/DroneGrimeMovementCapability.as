class UDroneGrimeMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeMovementComponent MoveComp;
	UDroneGrimeComponent GrimeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		GrimeComp = UDroneGrimeComponent::Get(Owner);

		MoveComp.ApplyMovementImpactsReturnPhysMats(true, this);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.GroundContact.AudioPhysMaterial != GrimeComp.GrimeMat)
			return false;

		if(MoveComp.GroundContact.AudioPhysMaterial == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.GroundContact.AudioPhysMaterial == GrimeComp.GrimeMat)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(GrimeComp.MovementSettings,this,EHazeSettingsPriority::Override);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
	}
};