class UOpportunityAttackPlayerQTECapability : UHazePlayerCapability
{
	//default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	UOpportunityAttackQTEComp QTEComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(TListedActors<ASkylineTor>().Single != nullptr)
			QTEComp = UOpportunityAttackQTEComp::Get(TListedActors<ASkylineTor>().Single);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (QTEComp == nullptr)
			return false;
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

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
		QTEComp.QTEPressed.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};