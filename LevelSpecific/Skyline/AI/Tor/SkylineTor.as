asset SkylineTorPlayerSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineTorEjectPlayerCapability);	
}

asset SkylineTorZoeSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineTorHammerAimPlayerCapability);
}

UCLASS(Abstract)
class ASkylineTor : ABasicAIGroundMovementCharacter
{
	// Remove
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability");

	// Add
	// default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorPlayerCollisionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorCutsceneCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorGeckoCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorGeckoSafetyProgressionCapability");

	// Phase Compounds	
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorGroundedPhaseBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorGroundedSecondPhaseBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHoveringPhaseBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHoveringSecondPhaseBehaviourCompoundCapability");

	// We need this to get them "grounded"
	default Mesh.ShadowPriority = EShadowPriority::GameplayElement;

	// Audio Crowd Control
	default CrowdControlComp.GroupTag = n"SkylineTor";
	default CrowdControlComp.AttenuationRange = 500;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent PlayerCollision;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine1")
	UGravityBladeCombatTargetComponent BladeTarget;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine1")
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
	UArcTraversalComponent TraversalComp;
	default TraversalComp.Method = USkylineJetpackTraversalMethod;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	URagdollComponent RagdollComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(SkylineTorPlayerSheet);
	default RequestCapabilityComp.PlayerSheets_Zoe.Add(SkylineTorZoeSheet);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine2)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipThrowResponseComponent ThrowResponseComp;
	default ThrowResponseComp.bNonThrowBlocking = true;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine2)
	UGravityWhipSlingAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine2)
	USkylineTorHammerStolenAutoAimComponent StolenAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = AutoAimComp)
	UTargetableOutlineComponent WhipSlingOutlineComp;

	UPROPERTY(DefaultComponent, Attach = StolenAutoAimComp)
	UTargetableOutlineComponent StolenOutlineComp;

	UPROPERTY(DefaultComponent)
	USkylineEnforcerFollowComponent FollowComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatEnforcerGloryDeathComponent GloryDeathComp; 

	UPROPERTY(DefaultComponent)
	USkylineTorDamageComponent TorDamageComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket="RightAttach")
	USkylineTorHoldHammerComponent HoldHammerComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UOpportunityAttackQTEComp QTEComp;

	UPROPERTY(DefaultComponent)
	USkylineTorPhaseComponent PhaseComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=LeftFoot)
	USkylineTorThrusterComponent LeftThrusterComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=RightFoot)
	USkylineTorThrusterComponent RightThrusterComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket="LeftAttach")
	USkylineTorDebrisComponent DebrisComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket="LeftAttach")
	USkylineTorPulseComponent PulseComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHoverComponent HoverComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerResponseComponent HammerResponseComp;

	UPROPERTY(DefaultComponent)
	USkylineTorExposedComponent ExposedComp;

	UPROPERTY(DefaultComponent)
	USkylineTorDeployMineComponent DeployMineComp;

	UPROPERTY(DefaultComponent)
	USkylineTorSmashComponent SmashComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket="Spine2")
	UGravityBladeOpportunityAttackTargetComponent OpportunityAttackTargetComp;

	UPROPERTY(DefaultComponent)
	USkylineTorOpportunityAttackComponent TorOpportunityAttackComp;

	UPROPERTY(DefaultComponent)
	UButtonMashComponent EjectButtonMash;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "HandBase_IK")
	USkylineTorOpportunityAttackCameraComponent OpportunityAttackCamera;
	default OpportunityAttackCamera.RelativeRotation = FRotator(0.0, -90.0, 0.0);

	UPROPERTY(DefaultComponent)
	USkylineTorBoloComponent BoloComp;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent WhirlwindForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UMovableCameraShakeComponent WhirlwindCameraShakeComp;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ZoeHammerAttackLastHit;

	UPROPERTY(DefaultComponent)
	USkylineTorDealDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	USkylineTorStormAttackComponent StormAttackComp;

	UPROPERTY(DefaultComponent)
	USkylineTorEjectComponent EjectComp;

	UPROPERTY(DefaultComponent)
	USkylineTorThrusterManagerComponent ThrusterManagerComponent;

	UPROPERTY(DefaultComponent)
	USpotLightComponent PersonalSpotLight;

	UHazeCameraComponent HammerBlowCamera;

	UPROPERTY()
	FSkylineTorPhaseComponentPhaseChangeSignature OnPhaseChange;
	UPROPERTY()
	FSkylineTorPhaseComponentSubPhaseChangeSignature OnSubPhaseChange;
	UPROPERTY()
	FSkylineTorPhaseComponentStateChangeSignature OnStateChange;

	bool bDisabledHammer;

	TArray<FName> AttackTags;

	int NumSpawnedGeckos = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
		UBasicAIHealthBarSettings::SetHealthBarSegments(this, 2, this);

		if(!bIsControlledByCutscene)
		{
			HealthBarComp.SetHealthBarEnabled(true);
			HealthBarComp.UpdateHealthBarSettings();
		}

		ApplySettings(SkylineEnforcerGravitySettings, this, EHazeSettingsPriority::Defaults);
		ApplySettings(SkylineEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);

		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTorTakeDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		UGravityWhippableSettings::SetDeathType(this, EGravityWhippableDeathType::Impact, this);
		UGravityWhippableSettings::SetEnableThrownDamage(this, true, this);
		ApplySettings(SkylineHeavyEnforcerMovementSettings, this, EHazeSettingsPriority::Defaults);
		USkylineEnforcerSettings::SetJumpEntranceDistance(this, 500, this);
		USkylineEnforcerSettings::SetJumpEntranceHeight(this, 250, this);

		// HACK: Adjust waypoint range due to larger collision. Proper way would be to use a separate navmesh built for larger AIs.
		UPathfollowingSettings::SetAtWaypointRange(this, 40, this);
		UPathfollowingSettings::SetNavmeshMaxProjectionRange(this, 2000, this);
		UGroundPathfollowingSettings::SetNavmeshMaxProjectionHeight(this, 2000, this);

		UBasicAISettings::SetChaseMoveSpeed(this, 200, this);
		UBasicAISettings::SetChaseMinRange(this, 300, this);
		UBasicAISettings::SetCircleStrafeMinRange(this, 0, this);
		UBasicAISettings::SetCircleStrafeMaxRange(this, 500, this);

		// We want heavy enforcers to have priority while in view
		UFitnessSettings::SetAdditionalOptimalFitness(this, 1, this);

		PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");
		PhaseComp.OnSubPhaseChange.AddUFunction(this, n"SubPhaseChange");
		PhaseComp.OnStateChange.AddUFunction(this, n"StateChange");

		// AutoAimComp.Disable(this);
		WhipTarget.Disable(this);

		HammerBlowCamera = UHazeCameraComponent::Get(TListedActors<ASkylineTorHammerStolenCamera>().GetSingle());

#if EDITOR
		SkylineTorDevToggleNamespace::GroundedAttacksGroup.BindOnChanged(this, n"OnGroupOptionChanged");
		SkylineTorDevToggleNamespace::HoveringAttacksGroup.BindOnChanged(this, n"OnGroupOptionChanged");
		SkylineTorDevToggleNamespace::Exposed.BindOnChanged(this, n"OnToggleBoolChanged");
#endif
	}

	private void BlockCombatCamera()
	{
		Game::Mio.BlockCapabilities(n"GravityBladeCombatCamera", this);
	}

	private void UnblockCombatCamera()
	{
		if(Game::Mio.IsCapabilityTagBlocked(n"GravityBladeCombatCamera"))
			Game::Mio.UnblockCapabilities(n"GravityBladeCombatCamera", this);
	}

	UFUNCTION()
	private void StateChange(ESkylineTorState NewState, ESkylineTorState OldState)
	{
		OnStateChange.Broadcast(NewState, OldState);
	}

	UFUNCTION()
	private void PhaseChange(ESkylineTorPhase NewPhase, ESkylineTorPhase OldPhase,
	                         ESkylineTorSubPhase NewSubPhase, ESkylineTorSubPhase OldSubPhase)
	{
		OnPhaseChange.Broadcast(NewPhase, OldPhase, NewSubPhase, OldSubPhase);
		USkylineTorEventHandler::Trigger_OnPhaseChange(this, FSkylineTorEventHandlerPhaseChangeData(NewPhase, OldPhase, NewSubPhase, OldSubPhase));
		HealthBarComp.SetHealthBarEnabled(NewPhase != ESkylineTorPhase::Gecko && NewPhase != ESkylineTorPhase::Dead);
		HealthBarComp.UpdateHealthBarSettings();

#if EDITOR
		SkylineTorDevToggleNamespace::Exposed.MakeVisible();
		if(NewPhase == ESkylineTorPhase::Grounded)
			SkylineTorDevToggleNamespace::GroundedAttacksGroup.MakeVisible();
		if(NewPhase == ESkylineTorPhase::Hovering)
			SkylineTorDevToggleNamespace::HoveringAttacksGroup.MakeVisible();

		for(auto Toggle : UHazeDevToggleSubsystem::Get().GetToggles())
		{
			OnToggleBoolChanged(Toggle.Value.bState);
		}
		
		for(auto ToggleGroup : UHazeDevToggleSubsystem::Get().GetToggleGroups())
		{
			FName Key = ToggleGroup.Key;
			FHazeInternalDevToggleGroup Group = ToggleGroup.Value;				

			FName GroupPath = NAME_None;
			if(NewPhase == ESkylineTorPhase::Grounded)
				GroupPath = SkylineTorDevToggleNamespace::GroundedAttacksGroup.GroupPath;
			if(NewPhase == ESkylineTorPhase::Hovering)
				GroupPath = SkylineTorDevToggleNamespace::HoveringAttacksGroup.GroupPath;
			if(Key == GroupPath)
				OnGroupOptionChanged(Group.ChosenOption);
		}
#endif
	}

	UFUNCTION()
	private void SubPhaseChange(ESkylineTorSubPhase NewSubPhase, ESkylineTorSubPhase OldSubPhase)
	{
		OnSubPhaseChange.Broadcast(NewSubPhase, OldSubPhase);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnRespawn()
	{
		UEnforcerEffectHandler::Trigger_OnRespawn(this);
		AnimComp.Reset();
		RemoveActorVisualsBlock(this);
		int PrevVoiceOverID = VoiceComp.GetVoiceOverID();
		VoiceComp.CreateNewVoiceID();
		BP_OnRespawn(PrevVoiceOverID);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnRespawn(int RemoveForVoiceID)
	{
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTorTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (Damage < SMALL_NUMBER)
			return;

		USkylineTorEventHandler::Trigger_OnTakeDamage(this);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return Mesh.GetSocketLocation(n"Head");
	}

	UFUNCTION()
	void ResetMove()
	{
		ResetMovement();
	}

	UFUNCTION()
	void SetHealth(float NewHealth)
	{
		if(HasControl())
			CrumbSetHealth(NewHealth);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetHealth(float NewHealth)
	{
		HealthComp.SetCurrentHealth(NewHealth);
	}

	UFUNCTION()
	void HideHealthBar()
	{
		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION()
	void HidePersonalSpotLight()
	{
		PersonalSpotLight.SetVisibility(false);
	}

	UFUNCTION()
	void ShowPersonalSpotLight()
	{
		PersonalSpotLight.SetVisibility(true);
	}


	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(HoldHammerComp.Hammer != nullptr)
		{
			HoldHammerComp.Hammer.AddActorDisable(this);
			bDisabledHammer = true;
		}
		UnblockCombatCamera();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(HoldHammerComp.Hammer != nullptr && bDisabledHammer)
		{
			HoldHammerComp.Hammer.RemoveActorDisable(this);
			bDisabledHammer = false;
		}
	}

	//
	// DEBUG
	// 

	UFUNCTION()
	private void OnGroupOptionChanged(FName NewState)
	{
		if(NewState == n"None")
			return;

		if(SkylineTorDevToggleNamespace::AttackModeAllGrounded.OptionName == NewState 
			|| SkylineTorDevToggleNamespace::AttackModeAllHovering.OptionName == NewState)
			AllAttacks();
		else
			OnlyAttack(NewState);
	}

	UFUNCTION()
	private void OnToggleBoolChanged(bool bNewState)
	{
		if(bNewState)
			Timer::SetTimer(this, n"HammerHit", 0.1);
	}

	private TArray<FName> GetAllAttackTags()
	{
		TArray<FName> AllTags;
		AllTags.Add(SkylineTorAttackTags::ChargeAttack);
		AllTags.Add(SkylineTorAttackTags::Clear);
		AllTags.Add(SkylineTorAttackTags::DiveAttack);
		AllTags.Add(SkylineTorAttackTags::EjectAttack);
		AllTags.Add(SkylineTorAttackTags::HammerSpiralAttack);
		AllTags.Add(SkylineTorAttackTags::HammerVolleyAttack);
		AllTags.Add(SkylineTorAttackTags::PulseAttack);
		AllTags.Add(SkylineTorAttackTags::SmashAttack);
		AllTags.Add(SkylineTorAttackTags::StormAttack);
		AllTags.Add(SkylineTorAttackTags::WhirlwindAttack);
		return AllTags;
	}

	UFUNCTION(DevFunction)
	void HammerHit()
	{
		HammerResponseComp.OnHit.Broadcast(0, EDamageType::Default, this);
	}

	UFUNCTION(DevFunction)
	void StartGecko()
	{
		HealthComp.SetCurrentHealth(0.5);
	}

	private void AllAttacks()
	{
		for(FName AttackTag : GetAllAttackTags())
		{
			if(IsCapabilityTagBlocked(AttackTag))
				UnblockCapabilities(AttackTag, this);
		}
	}

	private void OnlyAttack(FName OnlyTag)
	{		for(FName AttackTag : GetAllAttackTags())
		{
			if(!IsCapabilityTagBlocked(AttackTag))
				BlockCapabilities(AttackTag, this);
		}

		UnblockCapabilities(OnlyTag, this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FTransform T = Mesh.GetBoneTransform(n"HandBase_IK");
		Debug::DrawDebugCoordinateSystem(T.Location, T.Rotator(), 110.0);
	}
#endif
}

namespace SkylineTorAttackTags
{
	const FName Clear = n"Clear";
	const FName DiveAttack = n"DiveAttack";	
	const FName SmashAttack = n"SmashAttack";	
	const FName ChargeAttack = n"ChargeAttack";	
	const FName WhirlwindAttack = n"WhirlwindAttack";	
	const FName HammerSpiralAttack = n"HammerSpiralAttack";	
	const FName HammerVolleyAttack = n"HammerVolleyAttack";	
	const FName PulseAttack = n"PulseAttack";
	const FName StormAttack = n"StormAttack";
	const FName EjectAttack = n"EjectAttack";	
	const FName BoloAttack = n"BoloAttack";	
}

namespace SkylineTorDevToggleNamespace
{
	const FHazeDevToggleCategory TorCategory = FHazeDevToggleCategory(n"Tor");

	const FHazeDevToggleBool Exposed = FHazeDevToggleBool(TorCategory, n"Exposed");
	const FHazeDevToggleBool DontRecallHammer = FHazeDevToggleBool(TorCategory, n"DontRecallHammer");
	const FHazeDevToggleBool StayExposed = FHazeDevToggleBool(TorCategory, n"StayExposed");

	const FHazeDevToggleGroup GroundedAttacksGroup = FHazeDevToggleGroup(TorCategory, n"Grounded Attacks");
	const FHazeDevToggleOption AttackModeAllGrounded = FHazeDevToggleOption(GroundedAttacksGroup, n"AllGrounded");
	const FHazeDevToggleOption AttackModeClear = FHazeDevToggleOption(GroundedAttacksGroup, n"Clear");
	const FHazeDevToggleOption AttackModeSmashAttack = FHazeDevToggleOption(GroundedAttacksGroup, n"SmashAttack");	
	const FHazeDevToggleOption AttackModeWhirlwindAttack = FHazeDevToggleOption(GroundedAttacksGroup, n"WhirlwindAttack");	
	const FHazeDevToggleOption AttackModePulseAttack = FHazeDevToggleOption(GroundedAttacksGroup, n"PulseAttack");
	const FHazeDevToggleOption AttackModeBoloAttack = FHazeDevToggleOption(GroundedAttacksGroup, n"BoloAttack");
	const FHazeDevToggleOption AttackModeGroundedHammerVolleyAttack = FHazeDevToggleOption(GroundedAttacksGroup, n"HammerVolleyAttack");

	const FHazeDevToggleGroup HoveringAttacksGroup = FHazeDevToggleGroup(TorCategory, n"Hovering Attacks");
	const FHazeDevToggleOption AttackModeAllHovering = FHazeDevToggleOption(HoveringAttacksGroup, n"AllHovering");
	const FHazeDevToggleOption AttackModeDiveAttack = FHazeDevToggleOption(HoveringAttacksGroup, n"DiveAttack");	
	const FHazeDevToggleOption AttackModeHoveringHammerVolleyAttack = FHazeDevToggleOption(HoveringAttacksGroup, n"HammerVolleyAttack");
	const FHazeDevToggleOption AttackModeStormAttack = FHazeDevToggleOption(HoveringAttacksGroup, n"StormAttack");
	const FHazeDevToggleOption AttackModeEjectAttack = FHazeDevToggleOption(HoveringAttacksGroup, n"EjectAttack");
}