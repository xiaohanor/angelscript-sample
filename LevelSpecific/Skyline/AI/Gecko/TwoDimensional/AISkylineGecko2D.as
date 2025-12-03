asset Gecko2DSettings of USkylineGeckoSettings
{
	ChaseMinRange = 300.0;
	ChaseMoveSpeed = 1000.0;
}	


UCLASS(Abstract)
class AAISkylineGecko2D : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGecko2DBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoSpawnGravityCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"WallclimbingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoPathfindingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoDirectMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoOverturnedMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoThrownMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoFloorProbeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoLightningShieldCapability");
	
	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;

	UPROPERTY(DefaultComponent)
	USkylineGeckoComponent GeckoComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent ThrownObjectResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;
	default WhipTarget.MaximumAngle = 180.0;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Muzzle")
	USkylineGeckoBlobLauncherComponent BlobLauncher;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Muzzle")
	USkylineGeckoDakkaLauncherComponent DakkaLauncher;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerStumbleSheet);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UWallclimbingComponent WallclimbingComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)	
	UGravityWhippableComponent WhippableComp;

	USkylineGeckoSettings GeckoSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ApplyDefaultSettings(Gecko2DSettings);
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);
		ApplySettings(SkylineGeckoGravitySettings, this, EHazeSettingsPriority::Defaults);
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::VelocityAndImpact, this);
		UGravityWhippableSettings::SetThrownDamageRadius(this, 300, this);

		GeckoSettings = USkylineGeckoSettings::GetSettings(this);

		HealthComp.OnDie.AddUFunction(this, n"OnGeckoDie");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnGeckoTakeDamage");

		this.JoinTeam(SkylineGeckoTags::SkylineGeckoTeam);

		GeckoComp.OnOverturnedStart.AddUFunction(this, n"OnOverturnedStart");
		GeckoComp.OnOverturnedStop.AddUFunction(this, n"OnOverturnedStop");	

		UBasicAIMovementSettings::SetTurnDuration(this, 1, this);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		WhippableComp.OnThrown.AddUFunction(this, n"OnThrown");
	}

	UFUNCTION()
	private void OnThrown()
	{
		UBasicAIMovementSettings::SetAirFriction(this, 0, this);
		UBasicAIMovementSettings::SetGroundFriction(this, 0, this);
		UMovementGravitySettings::SetGravityScale(this, 0, this);
	}

	UFUNCTION()
	private void OnReset()
	{
		MoveComp.Reset(true);
		UBasicAIMovementSettings::ClearAirFriction(this, this);
		UBasicAIMovementSettings::ClearGroundFriction(this, this);
		UMovementGravitySettings::ClearGravityScale(this, this);
	}

	UFUNCTION()
	private void OnOverturnedStop()
	{		
		// UGravityWhipTargetComponent::Get(GeckoOrb).Disable(this);
	}

	UFUNCTION()
	private void OnOverturnedStart()
	{
		// UGravityWhipTargetComponent::Get(GeckoOrb).Enable(this);
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	private void OnGeckoDie(AHazeActor ActorBeingKilled)
	{
		USkylineGeckoEffectHandler::Trigger_OnDeath(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGeckoTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		USkylineGeckoEffectHandler::Trigger_OnTakeDamage(this);
	}
}
