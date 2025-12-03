class UPlayerHackingAudioLocationsCapability : UHazePlayerCapability
{
	UPROPERTY(EditDefaultsOnly)
	FName ComponentName = NAME_None;

	UPlayerTargetablesComponent TargetablesComponent;
	URemoteHackingPlayerComponent HackPlayerComp;
	UPlayerSwarmDroneHijackComponent SwarmDroneHijackComp;

	bool bIsInDroneForm = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		SwarmDroneHijackComp = UPlayerSwarmDroneHijackComponent::Get(Player);
		HackPlayerComp = URemoteHackingPlayerComponent::Get(Player);

		bIsInDroneForm = SwarmDroneHijackComp != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bIsInDroneForm)
		{
			return SwarmDroneHijackComp.IsHijackActive();
		} 
		else
		{
			return HackPlayerComp.bHackActive;
		}	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bIsInDroneForm)
		{
			return !SwarmDroneHijackComp.IsHijackActive();
		}
		else
		{
			return !HackPlayerComp.bHackActive;
		} 	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USceneComponent AttachComp = nullptr;
		if(ComponentName != NAME_None)
		 	AttachComp = Cast<USceneComponent>(GetHackTargetActor().GetComponent(USceneComponent, ComponentName));
		else
			AttachComp = GetHackTargetActor().GetRootComponent();
			
		Audio::OverridePlayerComponentAttach(Player, AttachComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Audio::ResetPlayerComponentAttach(Player);
	}

	private AActor GetHackTargetActor()
	{
		if(bIsInDroneForm)
        {
            auto Target = TargetablesComponent.GetPrimaryTargetForCategory(SwarmDroneTags::SwarmDroneHijackTargetableCategory);
            if(Target != nullptr)
                return Target.Owner;
            else
                return SwarmDroneHijackComp.Owner;
        }
		
		// This will return the player, otherwise use HackPlayerComp.CurrentHackingResponseComp.GetOwner();
		return HackPlayerComp.GetOwner();
	}
}