UCLASS(Abstract)
class AAIGeckoCompanion : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"GeckoCompanionBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoGroundMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoLeapMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoClimbSplineMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineGeckoDeathCapability");
	
	UPROPERTY(DefaultComponent)
	USkylineGeckoComponent GeckoComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.bAllowMultiGrab = false;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Drag;
	default WhipResponse.OffsetDistance = 600.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent ThrownObjectResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket = "Neck")
	UGravityWhipTargetComponent WhipTarget;
	default WhipTarget.MaximumAngle = 180.0;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket = "Hips")	
	UGeckoCompanionTail Tail;
	
	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UWallclimbingComponent WallclimbingComp;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncPositionComp;

	UPROPERTY(DefaultComponent)	
	UGravityWhippableComponent WhippableComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);

		ApplySettings(SkylineGeckoGravitySettings, this, EHazeSettingsPriority::Defaults);
		UGravityWhippableSettings::SetThrownDamageRadius(this, 300, this);

		HealthComp.OnTakeDamage.AddUFunction(this, n"OnGeckoTakeDamage");

		UBasicAIMovementSettings::SetTurnDuration(this, 1, this);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		WhippableComp.OnThrown.AddUFunction(this, n"OnThrown");

		Mesh.HideBoneByName(n"WeaponMount", EPhysBodyOp::PBO_None);
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

	UFUNCTION(NotBlueprintCallable)
	private void OnGeckoTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		USkylineGeckoEffectHandler::Trigger_OnTakeDamage(this);
	}
}
