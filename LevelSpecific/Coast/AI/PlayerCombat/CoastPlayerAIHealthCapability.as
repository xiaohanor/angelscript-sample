class UCoastPlayerAIHealthCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CoastPlayerAIHealthCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
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
		AHazeActor Actor = Cast<AHazeActor>(Owner);
		UPlayerHealthSettings::SetDisplayHealth(Actor, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AHazeActor Actor = Cast<AHazeActor>(Owner);
		Actor.ClearSettingsByInstigator(this);
	}
}