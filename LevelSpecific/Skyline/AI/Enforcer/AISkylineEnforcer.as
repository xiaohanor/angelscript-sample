asset SkylineEnforcerGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2200.0;
}

asset SkylineEnforcerMovementSettings of UBasicAIMovementSettings
{
	TurnDuration = 2.0;
}

asset SkylineHeavyEnforcerMovementSettings of UBasicAIMovementSettings
{
	TurnDuration = 2.0;
}


UCLASS(Abstract)
class AAISkylineEnforcerBase : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineEnforcerDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerJetpackTraverseMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAITeleportAlongRuntimeSplineCapabability");	
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIAnimationTeleportingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GravityBladeCombatEnforcerGloryDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GravityBladeCombatEnforcerGloryDeathSyncMeshCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AIEnemyGlobalDeathTrackerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineEnforcerPlayerInvulnerabilityCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIControlSideSwitchCapability");

	// We need this to get them "grounded"
	default Mesh.ShadowPriority = EShadowPriority::GameplayElement;

	// Audio Crowd Control
	default CrowdControlComp.GroupTag = n"SkylineEnforcer";
	default CrowdControlComp.AttenuationRange = 500;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIWeaponWielderComponent WeaponWielder;
	default WeaponWielder.bMaintainWeaponWorldScale = false; // Weapon should scale with wielder

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponse.bAllowMultiGrab = false;
	default WhipResponse.ForwardAxis = FVector(-1, 0, 0);
	default WhipResponse.bCanGloryKill = true;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine2")
	UGravityBladeCombatTargetComponent BladeTarget;
	//default BladeTarget.TargetName = FText::FromString("Enforcer");

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine2")
	UGravityBladeGrappleComponent GrappleTarget;
	default GrappleTarget.AutoAimMaxAngle = GravityBladeCombat::DefaultMaxCombatGrappleAngle;
	default GrappleTarget.MinimumDistanceFromPlayer = GravityBladeCombat::DefaultMinCombatGrappleDistance;
	default GrappleTarget.MaximumDistanceFromPlayer = GravityBladeCombat::DefaultMaxCombatGrappleDistance;
	default GrappleTarget.bIsCombatGrapple = true;

	UPROPERTY(DefaultComponent, Attach = "BladeTarget")
	UTargetableOutlineComponent BladeOutline;
	default BladeOutline.bAllowOutlineWhenNotPossibleTarget = false;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent VoxComp;

	UPROPERTY(DefaultComponent)
	UEnforcerJetpackComponent JetpackComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent JetpackTraversalAlphaSyncedComp;
	default JetpackTraversalAlphaSyncedComp.SyncRate = EHazeCrumbSyncRate::High; // Will only change during short periods

	UPROPERTY(DefaultComponent)
	UArcTraversalComponent TraversalComp;
	default TraversalComp.Method = USkylineJetpackTraversalMethod;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	URagdollComponent RagdollComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	// default RequestCapabilityComp.PlayerSheets.Add(PlayerTraversalSheet);

	UPROPERTY(DefaultComponent)
	UGravityWhipThrowResponseComponent ThrowResponseComp;
	default ThrowResponseComp.bNonThrowBlocking = true;

	UPROPERTY(DefaultComponent)
	USkylineEnforcerAnimationComponent EnforcerAnimComp;

	USkylineEnforcerSettings EnforcerSettings;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine2)
	UGravityWhipSlingAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = AutoAimComp)
	UTargetableOutlineComponent WhipSlingOutlineComp;

	UPROPERTY(DefaultComponent)
	USkylineEnforcerFollowComponent FollowComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatEnforcerGloryDeathComponent GloryDeathComp; 

	UPROPERTY(DefaultComponent)
	USkylineEnforcerSentencedComponent SentencedComp;

	UPROPERTY(DefaultComponent)
	UEnforcerChargeMeleeComponent ChargeMeleeComp;

	UPROPERTY(DefaultComponent)
	UBasicAIControlSideSwitchComponent ControlSwitchComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USceneComponent HaxMeshScaleComp;
	FVector HaxMeshScale = FVector::OneVector;

	UPROPERTY(DefaultComponent)
	UGravityWhippableComponent WhippableComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplySettings(SkylineEnforcerGravitySettings, this, EHazeSettingsPriority::Defaults);
		ApplySettings(SkylineEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 210.0, this);

		EnforcerSettings = USkylineEnforcerSettings::GetSettings(this);

		JetpackComp.OnRetreatStartEvent.AddUFunction(this, n"OnJetpackRetreatStart");

		HealthComp.OnDie.AddUFunction(this, n"OnEnforcerDie");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnEnforcerTakeDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");

		UBasicAISettings::SetTrackTargetsRequireVisibility(this, false, this);

		// HACK: Cutscene mesh gets broken by scale, so until this is handled by export or one-scaled model we hack it		
		Mesh.AttachToComponent(HaxMeshScaleComp, NAME_None, EAttachmentRule::KeepRelative);
		HaxMeshScale = Mesh.RelativeScale3D;
		HaxMeshScaleComp.RelativeScale3D = HaxMeshScale;
		Mesh.RelativeScale3D = FVector::OneVector;
		OnPreSequencerControl.AddUFunction(this, n"OnCutsceneStarted");
		OnPostSequencerControl.AddUFunction(this, n"OnCutsceneStopped");
	}

	UFUNCTION()
	private void OnCutsceneStarted(FHazePreSequencerControlParams Params)
	{
		// HACK, see above
		HaxMeshScaleComp.RelativeScale3D = FVector::OneVector;
	}

	UFUNCTION()
	private void OnCutsceneStopped(FHazePostSequencerControlParams Params)
	{
		// HACK, see above
		HaxMeshScaleComp.RelativeScale3D = HaxMeshScale;
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		int PrevVoiceOverID = VoiceComp.GetVoiceOverID();
		VoiceComp.CreateNewVoiceID();
		BP_OnRespawn(PrevVoiceOverID);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnRespawn()
	{
		UEnforcerEffectHandler::Trigger_OnRespawn(this);
		AnimComp.Reset();
		RemoveActorVisualsBlock(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnRespawn(int RemoveForVoiceID)
	{
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnJetpackRetreatStart()
	{
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	private void OnEnforcerDie(AHazeActor ActorBeingKilled)
	{
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnEnforcerTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (Damage < SMALL_NUMBER)
			return;

		UEnforcerEffectHandler::Trigger_OnTakeDamage(this);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return Mesh.GetSocketLocation(n"Head");
	}

	UFUNCTION(BlueprintCallable)
	void Follow(ASkylineHighwayCombatIsland Target)
	{
		FollowComp.Follow(Target);
	}
	
	UFUNCTION(BlueprintCallable)
	void Unfollow()
	{
		FollowComp.Unfollow();
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerWhippableBase : AAISkylineEnforcerBase
{
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine2")
	UGravityWhipTargetComponent WhipTarget;
	default WhipTarget.MaximumDistance = 1500;
	default WhipTarget.VisibleDistance = 2500;
	default WhipTarget.bCombatTarget = true;

	UPROPERTY(DefaultComponent, Attach = "WhipTarget")
	UTargetableOutlineComponent WhipOutline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnWhippableReset");
		HealthComp.OnDie.AddUFunction(this, n"OnWhippableDie");		
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		UBasicAIMovementSettings::SetTurnDuration(this, 1.5, this);
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		AutoAimComp.Disable(this);
		GrappleTarget.Disable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnWhippableReset()
	{
		WhipTarget.Enable(this);
		AutoAimComp.Enable(this);
		GrappleTarget.Enable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnWhippableDie(AHazeActor ActorBeingKilled)
	{
		WhipTarget.Disable(this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcer : AAISkylineEnforcerWhippableBase
{
	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;

	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"UpsideDownEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
}

UCLASS(Abstract)
class AAISkylineEnforcerAttackShip : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"AttackShipEnforcerBehaviourCompound");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerJetpackFleeAlongSplineMovementCapability");

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;

	UPROPERTY(DefaultComponent)
	UBasicAIFleeingComponent FleeComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerPatrol : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"PatrolEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");

	default AutoAimComp.SlingAutoAimCategories.Add(n"Pole");

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;

	UPROPERTY(DefaultComponent)
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USeeThroughPlayersPerceptionSight();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::VelocityAndImpact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		USkylineEnforcerSettings::SetJumpEntranceDistance(this, 1000, this);
		USkylineEnforcerSettings::SetChargeMeleeAttackActivationRange(this, 500.0, this);
		UBasicAISettings::SetChaseMinRange(this, 600.0, this);
//		UBasicAISettings::SetAttackRange(this, 700.0, this);
		UEnforcerRifleSettings::SetMinimumAttackRange(this, 200.0, this);
		UBasicAISettings::SetCircleStrafeMaxRange(this, 600.0, this);
		UBasicAISettings::SetCircleStrafeMinRange(this, 300.0, this);
		UBasicAISettings::SetCircleStrafeEnterRange(this, 500.0, this);

		RespawnComp.OnRespawn.AddUFunction(this, n"ResetMesh");
	}

	UFUNCTION(NotBlueprintCallable)
	protected void ResetMesh()
	{
		RagdollComp.bAllowRagdoll.Clear(this);
		DetachFromActor();
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerHighway : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"HighwayEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"HighwayEnforcerKillAtRangeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineEnforcerDeployMovementCapability");

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::VelocityAndImpact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		UBasicAITraversalSettings::SetChaseMinRange(this, 2000, this, EHazeSettingsPriority::Gameplay);
		UBasicAISettings::SetShuffleDurationMin(this, 2, this);
		UBasicAISettings::SetShuffleDurationMax(this, 4, this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerHeavyHighway : AAISkylineEnforcerBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"HighwayEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BoundsHighwayEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"UpsideDownEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");
	default WeaponWielder.BaseWeaponScale = 1.2;

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		ApplySettings(SkylineHeavyEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 270.0, this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerClub : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"ClubEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::VelocityAndImpact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		USkylineEnforcerSettings::SetJumpEntranceDistance(this, 1000, this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerHeavyClub : AAISkylineEnforcerBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"ClubEnforcerHeavyBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineEnforcerBodyFieldCapability");
	default WeaponWielder.BaseWeaponScale = 1.2;

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	default HealthComp.MaxHealth = 6.0;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USkylineEnforcerBodyFieldComponent BodyFieldComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		ApplySettings(SkylineHeavyEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 270.0, this);
		USkylineEnforcerSettings::SetJumpEntranceDistance(this, 500, this);
		USkylineEnforcerSettings::SetJumpEntranceHeight(this, 250, this);

		// HACK: Adjust waypoint range due to larger collision. Proper way would be to use a separate navmesh built for larger AIs.
		UPathfollowingSettings::SetAtWaypointRange(this, 40, this);

		// We want heavy enforcers to have priority while in view
		UFitnessSettings::SetAdditionalOptimalFitness(this, 1, this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerEliteRocketLauncher : AAISkylineEnforcerBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"RocketLauncherEliteEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineEnforcerBodyFieldCapability");
	default WeaponWielder.BaseWeaponScale = 1.2;

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	default HealthComp.MaxHealth = 6.0;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USkylineEnforcerBodyFieldComponent BodyFieldComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		ApplySettings(SkylineHeavyEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 270.0, this);
		USkylineEnforcerSettings::SetJumpEntranceDistance(this, 500, this);
		USkylineEnforcerSettings::SetJumpEntranceHeight(this, 250, this);

		// HACK: Adjust waypoint range due to larger collision. Proper way would be to use a separate navmesh built for larger AIs.
		UPathfollowingSettings::SetAtWaypointRange(this, 40, this);

		// We want heavy enforcers to have priority while in view
		UFitnessSettings::SetAdditionalOptimalFitness(this, 1, this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerShield : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"ShieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"UpsideDownShieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UEnforcerShieldDamageComponent DamageComp;
	default DamageComp.bTakeDamageFromWhipThrow = false;

	UPROPERTY(DefaultComponent)
	UEnforcerShieldComponent ShieldComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ShieldComp.OnDisableShield.AddUFunction(this, n"OnDisableShield");
		ShieldComp.OnResetShield.AddUFunction(this, n"OnResetShield");
		WhipTarget.Disable(this);
	}

	private void OnWhippableReset() override
	{
		WhipTarget.Disable(this);
		AutoAimComp.Enable(this);
	}

	UFUNCTION()
	private void OnDisableShield()
	{
		WhipTarget.Enable(this);
	}

	UFUNCTION()
	private void OnResetShield()
	{
		WhipTarget.Disable(this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerHighwayShield : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"HighwayShieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BoundsHighwayShieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UEnforcerShieldDamageComponent DamageComp;
	
	UPROPERTY(DefaultComponent)
	UEnforcerShieldComponent ShieldComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);

		ShieldComp.OnDisableShield.AddUFunction(this, n"OnDisableShield");
		ShieldComp.OnResetShield.AddUFunction(this, n"OnResetShield");
		WhipTarget.Disable(this);
	}

	private void OnWhippableReset() override
	{
		WhipTarget.Disable(this);
		AutoAimComp.Enable(this);
	}

	UFUNCTION()
	private void OnDisableShield()
	{
		WhipTarget.Enable(this);
	}

	UFUNCTION()
	private void OnResetShield()
	{
		WhipTarget.Disable(this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerHeavyHighwayShield : AAISkylineEnforcerBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"HighwayShieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BoundsHighwayShieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"EnforcerJetpackTraverseMovementCapability");
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;
	default WeaponWielder.BaseWeaponScale = 1.2;

	UPROPERTY(DefaultComponent)
	UEnforcerShieldDamageComponent DamageComp;
	
	UPROPERTY(DefaultComponent)
	UEnforcerShieldComponent ShieldComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		ApplySettings(SkylineHeavyEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerArm : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"ArmEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"UpsideDownArmEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Drag;

	UPROPERTY(DefaultComponent)
	UEnforcerArmDamageComponent DamageComp;
	default DamageComp.bTakeDamageFromWhipThrow = false;

	UPROPERTY(DefaultComponent)
	UEnforcerArmComponent ArmComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WhipTarget.Disable(this);
	}

	private void OnWhippableReset() override
	{

	}
}

UCLASS(Abstract)
class AAISkylineEnforcerBoots : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"BootsEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"UpsideDownBootsEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Drag;

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;
	default DamageComp.bTakeDamageFromWhipThrow = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFootSole")
	UStaticMeshComponent LeftLeg;
	default LeftLeg.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFootSole")
	UStaticMeshComponent RightLeg;
	default RightLeg.bCanEverAffectNavigation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HealthComp.OnDie.AddUFunction(this, n"OnBootsDie");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnBootsReset");
	}

	UFUNCTION()
	private void OnBootsReset()
	{
		LeftLeg.SetVisibility(true, true);
		RightLeg.SetVisibility(true, true);
	}

	UFUNCTION()
	private void OnBootsDie(AHazeActor ActorBeingKilled)
	{
		LeftLeg.SetVisibility(false, true);
		RightLeg.SetVisibility(false, true);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerForceField : AAISkylineEnforcerWhippableBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"ForceFieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"UpsideDownForceFieldEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	USkylineEnforcerForceFieldDamageComponent DamageComp;
	default DamageComp.bTakeDamageFromWhipThrow = false;

	UPROPERTY(DefaultComponent)
	USkylineEnforcerForceFieldComponent ForceFieldComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	protected void OnRespawn() override
	{
		Super::OnRespawn();
		UEnforcerEffectHandler::Trigger_OnRespawn(this);
	}
}

UCLASS(Abstract)
class AAISkylineEnforcerStatic : AAISkylineEnforcerWhippableBase
{
	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;
	default DamageComp.bTakeDamageFromWhipThrow = false;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Align")
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;

	default CapabilityComp.DefaultCapabilities.Add(n"StaticEnforcerBehaviourCompoundCapability");
}