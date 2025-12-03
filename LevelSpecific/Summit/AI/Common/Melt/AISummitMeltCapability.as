class UAISummitMeltCapability : UHazeCapability
{
	USummitMeltComponent MeltComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MeltComp.Update(DeltaTime);
	}
}