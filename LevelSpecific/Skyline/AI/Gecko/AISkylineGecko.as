asset SkylineGeckoGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2200.0;
}

UCLASS(Abstract)
class AAISkylineGecko : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoGroundMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoPerchMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoLeapMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoConstrainAttackMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoClimbSplineMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoWhipLiftedMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoThrownMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoArenaBoundsKillCapability");

	// Do not auto disable geckos until SkylineTorGeckoSafetyProgressionCapability deactivates (when Tor boss leave gecko phase)
	default DisableComp.bAutoDisable = false;

	UPROPERTY(DefaultComponent)
	USkylineGeckoComponent GeckoComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.bAllowMultiGrab = false;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent ThrownObjectResponseComp;

	UPROPERTY(DefaultComponent)
	USkylineTorDebrisResponseComponent TorThrownObjectResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket = "WeaponMount")
	UGravityWhipTargetComponent WhipTarget;
	default WhipTarget.MaximumAngle = 180.0;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutline;

	UPROPERTY(DefaultComponent, Attach=WhipTarget)
	UGravityWhipSlingAutoAimComponent WhipSlingAutoAim;
	default WhipSlingAutoAim.MaxAimAngle = 32;

	UPROPERTY(DefaultComponent, Attach = WhipSlingAutoAim)
	UTargetableOutlineComponent WhipSlingOutlineComp;
	
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "WeaponMount")
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent, Attach = BladeTarget)
	UTargetableOutlineComponent BladeOutline;
	default BladeOutline.bAllowOutlineWhenNotPossibleTarget = false;

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
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncPositionComp;

	UPROPERTY(DefaultComponent)	
	UGravityWhippableComponent WhippableComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "WeaponMount")
	UGravityBladeGrappleComponent GrappleTarget;
	default GrappleTarget.AutoAimMaxAngle = GravityBladeCombat::DefaultMaxCombatGrappleAngle;
	default GrappleTarget.MinimumDistanceFromPlayer = GravityBladeCombat::DefaultMinCombatGrappleDistance;
	default GrappleTarget.MaximumDistanceFromPlayer = GravityBladeCombat::DefaultMaxCombatGrappleDistance;
	default GrappleTarget.bIsCombatGrapple = true;

	UPROPERTY(DefaultComponent)	
	UHazeDecalComponent PounceDecal;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent ConstrainCamera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent ConstrainCamera2;

	AHazePlayerCharacter AggroTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);

		ApplySettings(SkylineGeckoGravitySettings, this, EHazeSettingsPriority::Defaults);
		UGravityWhippableSettings::SetThrownDamageRadius(this, 300, this);
		
		// Ensure we have our gecko team set up
		GeckoComp.Initialize(); 

		HealthComp.OnTakeDamage.AddUFunction(this, n"OnGeckoTakeDamage");

		UBasicAIMovementSettings::SetTurnDuration(this, 3, this);

		// No path finding since arena is convex and free from obstacles and we want to keep things cheap.
		UPathfollowingSettings::SetIgnorePathfinding(this, true, this, EHazeSettingsPriority::Defaults);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		WhippableComp.OnThrown.AddUFunction(this, n"OnThrown");

		// To keep things cheap (less netfunction calls) we start with alternating targets and stick with that even after respawn
		// Note that we assume spawn order is the same on both sides in network (true for the nightclub scenario)
		// Can't use team since it might have desynced number of nullptr members, use counter on Mr Hammer instead.
		AggroTarget	= Game::Zoe;
		ASkylineTor HammerBoss = TListedActors<ASkylineTor>().Single;
		if (HammerBoss != nullptr)
		{
			if ((HammerBoss.NumSpawnedGeckos % 2) == 0)
				AggroTarget = Game::Mio;
			HammerBoss.NumSpawnedGeckos++;
		}
		TargetingComponent.SetTargetLocal(AggroTarget);
		SetActorControlSide(AggroTarget);

		UBasicAISettings::SetCircleStrafeMaxRange(this, 800, this);
		UBasicAISettings::SetCircleStrafeEnterRange(this, 600, this);
		UBasicAISettings::SetCircleStrafeMinRange(this, 250, this);

		UBasicAISettings::SetCrowdAvoidanceForce(this, 1000, this);
		UBasicAISettings::SetCrowdAvoidanceMinRange(this, 160, this);
		UBasicAISettings::SetCrowdAvoidanceMaxRange(this, 350, this);

		UBasicAISettings::SetEvadeRange(this, 300, this);

		PounceDecal.AddComponentVisualsBlocker(this);
	}

	UFUNCTION()
	private void OnThrown()
	{
		UBasicAIMovementSettings::SetAirFriction(this, 0, this);
		UBasicAIMovementSettings::SetGroundFriction(this, 0, this);
		UMovementGravitySettings::SetGravityScale(this, 0, this);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		MoveComp.Reset(true);
		UBasicAIMovementSettings::ClearAirFriction(this, this);
		UBasicAIMovementSettings::ClearGroundFriction(this, this);
		UMovementGravitySettings::ClearGravityScale(this, this);
		TargetingComponent.SetTargetLocal(AggroTarget);
		HealthComp.RemoveInvulnerable(); // failsafe if for some reason not cleared by behaviour.
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGeckoTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		USkylineGeckoEffectHandler::Trigger_OnTakeDamage(this);
	}
}

namespace SkylineGeckoTags
{
	const FName SkylineGeckoTeam = n"SkylineGeckoTeam";
	const FName SkylineGeckoPlayerPinnedInstigatorTag = n"SkylineGeckoPlayerPinnedInstigator";
}