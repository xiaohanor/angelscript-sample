namespace SwarmDroneTags
{
	const FName BlockedWhileInSwarmDroneBounce = n"BlockedWhileInSwarmDroneBounce";
}

UCLASS(Abstract)
class USwarmDroneBounceComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	private USwarmDroneBounceSettings DefaultSettings;
	
	private AHazePlayerCharacter Player;
	USwarmDroneBounceSettings Settings;
	UPlayerSwarmDroneComponent SwarmDroneComp;

	// Bouncing
	bool bIsInBounceState = false;
	uint LastResolverBounceFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Player.ApplyDefaultSettings(DefaultSettings);

		Settings = USwarmDroneBounceSettings::GetSettings(Player);
		SwarmDroneComp = UPlayerSwarmDroneComponent::Get(Player);
	}

	bool HasResolverBouncedThisFrame() const
	{
		return LastResolverBounceFrame >= Time::FrameNumber;
	}

	bool CanBounce() const
	{
		if(SwarmDroneComp.bSwarmModeActive)
			return false;

		if(SwarmDroneComp.bSwarmTransitionActive)
			return false;

		if(SwarmDroneComp.bDeswarmifying)
			return false;

		if(SwarmDroneComp.bHovering)
			return false;

		if(SwarmDroneComp.bHoverDashing)
			return false;

		if(SwarmDroneComp.bSwarmDashing)
			return false;

		if(SwarmDroneComp.bFloating)
			return false;

		return true;
	}
};