
class UPlayerBabyDragonAnimationCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 200;
	default CapabilityTags.Add(BabyDragon::BabyDragon);

	UPlayerBabyDragonComponent DragonComp;
	UPlayerAirDashComponent AirDashComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerBabyDragonComponent::Get(Owner);
		AirDashComp = UPlayerAirDashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DragonComp.BabyDragon == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonComp.BabyDragon == nullptr)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(AirDashComp.IsAirDashing()
		&& IsActioning(ActionNames::SecondaryLevelAbility))
			DragonComp.RequestBabyDragonLocomotion(n"BackpackDragonHover");

		DragonComp.RequestBabyDragonLocomotion(n"Movement");

	}
};