
class UIslandOverseerTowardsChaseSpeedBoostBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	AHazeCharacter Character;
	AHazePlayerCharacter Target;
	UIslandOverseerProximityKillPointComponent KillPointComp;	
	float SpeedBoost = 250;
	float SpeedBoostDistance = 600;

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

	void DeactivateBehaviour() override
	{
			Super::DeactivateBehaviour();
		for(AHazePlayerCharacter Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector SpeedBoostLocation = KillPointComp.WorldLocation + Owner.ActorForwardVector * SpeedBoostDistance;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Owner.ActorForwardVector.DotProduct(Player.ActorLocation - SpeedBoostLocation) < 0)
			{
				float Alpha = 1 - Math::Clamp(Player.ActorLocation.Distance(SpeedBoostLocation) / SpeedBoostDistance, 0, 1);
				float AddSpeed = SpeedBoost * Alpha;
				UPlayerSprintSettings::SetMaximumSpeed(Player, 600 + AddSpeed, this);
				UPlayerSprintSettings::SetMinimumSpeed(Player, 500 + AddSpeed, this);
			}
			else
				Player.ClearSettingsByInstigator(this);
		}
	}
}