struct FDentistBossCupTargetRestrainedPlayerActivationParams
{
	
}

class UDentistBossCupTargetRestrainedPlayerCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossCupTargetRestrainedPlayerActivationParams Params;

	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossCupTargetRestrainedPlayerActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetComp.Target.Clear(Dentist);
		TargetComp.Target.Apply(TargetComp.CupRestrainedPlayer, Dentist, EInstigatePriority::Normal);
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};