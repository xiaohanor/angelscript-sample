class USkylineTorFollowHammerBehaviour : UBasicBehaviour
{
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!HoldHammerComp.bDetached)
			return false;
		if(Owner.ActorLocation.IsWithinDist(HoldHammerComp.Hammer.ActorLocation, Settings.FollowHammerMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Owner.ActorLocation.IsWithinDist(HoldHammerComp.Hammer.ActorLocation, Settings.FollowHammerMinRange))
		{
			DestinationComp.MoveTowardsIgnorePathfinding(HoldHammerComp.Hammer.ActorLocation - HoldHammerComp.Hammer.ActorForwardVector * 500, Settings.FollowHammerMoveSpeed);
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HoldHammerComp.Hammer.TargetingComponent.Target);
		if(Player != nullptr && TargetComp.Target != Player.OtherPlayer)
			TargetComp.SetTarget(Player.OtherPlayer);
		if(TargetComp.Target != nullptr)
			DestinationComp.RotateTowards(TargetComp.Target);
	}
}
