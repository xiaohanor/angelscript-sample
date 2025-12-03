UCLASS(Abstract)
class AAISkylineRappeller : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineRappellerMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineEnforcerDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RappellerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineRappellerRopeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineRappellerCuttableRopeCapability");

	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::StrafeMovement;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIWeaponWielderComponent WeaponWielder;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	// Capsule component that will match height with Mio along cable, so she can cut the rope.
	UPROPERTY(DefaultComponent)
	USkylineRappellerRopeCollisionComponent RopeCollision;

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine2")
	UCableComponent CableComp;
	default CableComp.CableLength = 400.0;
	default CableComp.EndLocation = FVector(0.0, 0.0, 200.0);
	
	USkylineEnforcerSettings EnforcerSettings;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine2)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	USkylineEnforcerFollowComponent FollowComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplySettings(SkylineEnforcerGravitySettings, this, EHazeSettingsPriority::Defaults);

		EnforcerSettings = USkylineEnforcerSettings::GetSettings(this);

		HealthComp.OnDie.AddUFunction(this, n"OnEnforcerDie");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnEnforcerTakeDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReset()
	{
		UEnforcerEffectHandler::Trigger_OnRespawn(this);
		WhipTarget.Enable(this);
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	private void OnEnforcerDie(AHazeActor ActorBeingKilled)
	{
		auto Data = FEnforcerEffectOnDeathData();
		Data.DeathDuration = EnforcerSettings.DeathDuration;
		UEnforcerEffectHandler::Trigger_OnDeath(this, Data);
		WhipTarget.Disable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnEnforcerTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (Damage < SMALL_NUMBER)
			return;

		UEnforcerEffectHandler::Trigger_OnTakeDamage(this);
	}
}

UCLASS(Meta = (ComposeSettingsOnto = "UBasicAISettings"))
class USkylineRappellerAISettings : UBasicAISettings
{
	default bOverride_AttackRange = true;
	default AttackRange = 10000.0;
}