UCLASS(Abstract)
class AAISummitStoneBeastSlasher : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastSlasherCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastSlasherTentaclesCapability");

	UPROPERTY(DefaultComponent)
	USummitStoneBeastSlasherTentaclesComponent TentacleComp;

	UPROPERTY(DefaultComponent, Attach = "TentacleComp")
	USummitStoneBeastSlasherTentacleDecalComponent TentacleDecalComp;
	
	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent SwordResponseComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatTargetComponent SwordTargetComp;
	default SwordTargetComp.bCanRushTowards = false;
	default SwordTargetComp.RelativeLocation = FVector(0,0, 100);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(BaseSummitStoneBeastCritterPlayerPinnedKnockdownSheet);

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	USummitStoneBeastSlasherSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Settings = USummitStoneBeastSlasherSettings::GetSettings(this);
		SwordResponseComp.OnHit.AddUFunction(this,n"OnSwordHit");
		HealthComp.OnDie.AddUFunction(this, n"OnCritterDie");
	}

	TPerPlayer<float> HackInvulnerabilityTimes;

	UFUNCTION()
	private void OnSwordHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		// Hack to not take multiple damage from one sword strike
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Instigator);
		if (Player == nullptr)
			Player = Game::Mio;
		if (HackInvulnerabilityTimes[Player] > Time::GameTimeSeconds)
			return;
		HackInvulnerabilityTimes[Player] = Time::GameTimeSeconds + 0.5;
		// End hack, remove when sword handles this instead

		HealthComp.TakeDamage(Settings.DamageFromSword, EDamageType::MeleeSharp, Cast<AHazeActor>(CombatComp.Owner));
		if (HealthComp.IsAlive())
			USummitStoneBeastSlasherEffectHandler::Trigger_OnTakeDamage(this);
	}

	UFUNCTION()
	private void OnCritterDie(AHazeActor ActorBeingKilled)
	{
		USummitStoneBeastSlasherEffectHandler::Trigger_OnDeath(this);
	}
}