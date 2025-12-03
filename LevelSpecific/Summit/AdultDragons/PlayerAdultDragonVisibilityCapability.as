
class UPlayerAdultDragonVisibilityCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);

	default DebugCategory = n"AdultDragon";

	AHazePlayerCharacter Player;
	UPlayerAdultDragonComponent DragonComp;

 	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DragonComp = UPlayerAdultDragonComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		DragonComp.RemoveDragonVisualsBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		DragonComp.AddDragonVisualsBlock(this);
	}

};