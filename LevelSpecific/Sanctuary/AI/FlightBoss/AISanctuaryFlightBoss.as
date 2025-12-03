class AAISanctuaryFlightBoss : ABasicAICharacter
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	// Behaviours, screw behaviour sets
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossFindTargetBehaviour");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossBehaviourFireballCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossBehaviourTentacleStabCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossBehaviourTentacleSweepCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossBehaviourTentacleSlashCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicBehaviourTrackTargetCapability");

	// Regular capabilities
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossIdleTentacleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryFlightBossTurnInPLaceCapability"); 
	
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = LeftEye)
	USanctuaryFireBallLauncherComponent FireBallLauncherComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightEar)
	USanctuaryFlightBossTentacleComponent TentacleComp;
	
	UPROPERTY(DefaultComponent)
	USanctuaryFlightBossComponent BossComp;

	bool bFlightStarted = false;
	bool bAwake = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UBasicAIDamageSettings::SetIgnoreHealthComponent(this, true, this, EHazeSettingsPriority::Gameplay);
		
		// Start without behaviour
		BlockCapabilities(n"Behaviour", this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			USanctuaryFlightComponent FlightComp = USanctuaryFlightComponent::Get(Player);
			if (FlightComp != nullptr)
				FlightComp.OnStartFlying.AddUFunction(this, n"OnPlayerStartFlight");
		}
	}

	UFUNCTION()
	private void OnPlayerStartFlight(USanctuaryFlightComponent FlightComp)
	{
		if (bFlightStarted)
			return;
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::None)
			FireBall();
		bFlightStarted = true;
	}

	void Awaken()
	{
		if (bAwake)
			return;
		UnblockCapabilities(n"Behaviour", this);
		bAwake = true;
	}

	UFUNCTION(DevFunction)
	void FireBall()
	{
		Awaken();
		BossComp.CurrentAttack = ESanctuaryFlightBossAttack::FireBall;
		BossComp.SwitchTarget(1.0);
	}

	UFUNCTION(DevFunction)
	void TentacleSweep()
	{
		Awaken();
		BossComp.CurrentAttack = ESanctuaryFlightBossAttack::TentacleSweep;
		BossComp.SwitchTarget(1.0);
	}

	UFUNCTION(DevFunction)
	void TentacleSlash()
	{
		Awaken();
		BossComp.CurrentAttack = ESanctuaryFlightBossAttack::TentacleSlash;
		BossComp.SwitchTarget(1.0);
	}

	UFUNCTION(DevFunction)
	void TentacleStab()
	{
		Awaken();
		BossComp.CurrentAttack = ESanctuaryFlightBossAttack::TentacleStab;
		BossComp.SwitchTarget(1.0);
	}

	UFUNCTION(DevFunction)
	void StopAttacking()
	{
		BossComp.CurrentAttack = ESanctuaryFlightBossAttack::None;
		BossComp.SwitchTarget(1.0);
	}
}

