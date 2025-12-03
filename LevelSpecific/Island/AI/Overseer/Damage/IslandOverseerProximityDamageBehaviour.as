
class UIslandOverseerProximityDamageBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	UIslandOverseerProximityKillPointComponent KillPointComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		KillPointComp = UIslandOverseerProximityKillPointComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.IsPlayerDead())
				continue;
			if(Owner.ActorForwardVector.DotProduct(Player.ActorLocation - KillPointComp.WorldLocation) > 0)
				continue;
			if(!Player.HasControl())
				continue;
			Player.KillPlayer(DeathEffect = KillPointComp.DeathEffect);
		}
	}
}