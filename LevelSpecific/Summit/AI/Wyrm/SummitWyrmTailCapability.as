class USummitWyrmTailCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default CapabilityTags.Add(n"SummitWyrm");

	USummitWyrmSettings Settings;

	USummitWyrmTailComponent TailComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailComponent = USummitWyrmTailComponent::Get(Owner);
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
	void TickActive(float DeltaTime)
	{
		TailComponent.UpdateTail(DeltaTime);
	}
}
