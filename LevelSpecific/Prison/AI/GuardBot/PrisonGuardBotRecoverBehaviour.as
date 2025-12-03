class UPrisonGuardBotRecoverBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UPrisonGuardBotSettings GuardBotSettings;
	UHazeActorRespawnableComponent RespawnComp;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GuardBotSettings = UPrisonGuardBotSettings::GetSettings(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Never continue recovering when we reincarnate
		Cooldown.Set(0.5);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > GuardBotSettings.RecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + Owner.ActorForwardVector * 100.0 + Owner.ActorUpVector * 500.0, GuardBotSettings.RecoverMoveSpeed);
	}
}

