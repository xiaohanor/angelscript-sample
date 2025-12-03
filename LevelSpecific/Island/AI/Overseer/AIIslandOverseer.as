event void FIslandOverseerPhaseChangeEvent(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase);
event void FIslandOverseerIntroCombatPhaseStartEvent();
event void FIslandOverseerFloodPhaseStartEvent();
event void FIslandOverseerPovCombatPhaseStartEvent();
event void FIslandOverseerSideChasePhaseStartEvent();
event void FIslandOverseerTowardsChasePhaseStartEvent();
event void FIslandOverseerDoorPhaseStartEvent();
event void FIslandOverseerDoorCutHeadPhaseStartEvent();
event void FIslandOverseerDeadPhaseStartEvent();
event void FIslandOverseerFloodStartedEvent();
event void FIslandOverseerFloodStoppedEvent();

event void FIslandOverseerSideChaseArrivedEvent();
event void FIslandOverseerIntroCombatHalfHealthEvent();

event void FIslandOverseerCutHeadStartEvent();
event void FIslandOverseerCutHeadSuccessEvent();

class AAIIslandOverseer : AHazeCharacter
{
	// Overlaps are expensive for stuff that moves frequently
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.CollisionProfileName = n"NoCollision";
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIUpdateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAITakeDamageCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIAnimationMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIRequestOverrideFeatureCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerTrackCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerIntroCombatCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerFloodCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerPovCombatCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerSideChaseCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerTowardsChaseCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerDoorCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerDoorCutHeadCompoundCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerFloodRespawnCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerSideChaseRespawnCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerTowardsChaseRespawnCapability");	

	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerTakeDamageCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerPovCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerDoorEyeFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerVisorCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerSpotLightFaderCapability");

	UPROPERTY(DefaultComponent, ShowOnActor, meta = (ShowOnlyInnerProperties))
    UBasicBehaviourComponent BehaviourComponent;
	
    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIAnimationComponent AnimComp;

	UPROPERTY(DefaultComponent)
	UBasicAIDestinationComponent DestinationComp;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 3.0;

	UPROPERTY(DefaultComponent)
	UBasicAIVoiceOverComponent VoiceComp;

	UPROPERTY(DisplayName = "OnDie")
	FOnBasicAIDie OnAIDie;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerTakeDamageComponent DamageComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine1)
	UIslandOverseerLeftLaunchPointContainerComponent LeftLaunchPointContainerComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Spine1)
	UIslandOverseerRightLaunchPointContainerComponent RightLaunchPointContainerComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerMissileProjectileLauncherComponent MissileProjectileLauncherComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	UIslandRedBlueImpactResponseComponent DamageResponseComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=LeftEye)
	UIslandOverseerDeployEyeComponent EyeLeft;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=RightEye)
	UIslandOverseerDeployEyeComponent EyeRight;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=LeftEye)
	UIslandOverseerLaserAttackEmitter LeftLaserEmitter;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=RightEye)
	UIslandOverseerLaserAttackEmitter RightLaserEmitter;

	UPROPERTY(DefaultComponent)
	UIslandOverseerPhaseComponent PhaseComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMoveComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	UIslandOverseerFloodAttackComponent FloodAttackComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerPovComponent PovComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerSideChaseComponent SideChaseComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerDoorComponent DoorComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerFloodComponent FloodComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerTowardsChaseComponent TowardsChaseComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	UIslandOverseerReturnGrenadeLauncherComponent ReturnGrenadeLauncherComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	UIslandOverseerWallBombLauncherComponent WallBombLauncherComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	UIslandOverseerVisorComponent VisorComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=LeftEye)
	USceneComponent TempLeftEyePanel;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=RightEye)
	USceneComponent TempRightEyePanel;

	UPROPERTY(DefaultComponent)
	UIslandOverseerDeployRollerManagerComponent RollerManagerComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=LeftArmAttach)
	UIslandOverseerDeployRollerComponent LeftRollerComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=RightArmAttach)
	UIslandOverseerDeployRollerComponent RightRollerComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerProximityKillPointComponent ProximityKillPointComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	UIslandOverseerPeekBombLauncherComponent PeekBombLauncher;

	UPROPERTY(DefaultComponent)
	UIslandOverseerDoorAcidComponent DoorAcidComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerAdvanceComponent AdvanceComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerLaserBombComponent LaserBombComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerDoorShakeComponent DoorShakeComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerTremorComponent TremorComp;

	UPROPERTY(DefaultComponent)
	USpotLightComponent IdleSpotLight;
	
	UPROPERTY(DefaultComponent)
	USpotLightComponent IntroCombatSpotLight;
	default IntroCombatSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	USpotLightComponent FloodSpotLight;
	default FloodSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	USpotLightComponent PovSpotLight;
	default PovSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	USpotLightComponent SideChaseSpotLight;
	default SideChaseSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	USpotLightComponent TowardsChaseSpotLight;
	default TowardsChaseSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	USpotLightComponent DoorSpotLight;
	default DoorSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	USpotLightComponent DoorCutHeadSpotLight;
	default DoorCutHeadSpotLight.bVisible = false;

	UPROPERTY(DefaultComponent)
	UIslandOverseerSpotLightComponent SpotLightComp;
	default SpotLightComp.CurrentSpotLight = IdleSpotLight;

	UPROPERTY(DefaultComponent)
	UIslandOverseerControlCraneComponent ControlCraneComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerRedBlueDamageComponent OverseerRedBlueDamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent CutHeadStartFx;
	default CutHeadStartFx.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	UNiagaraComponent EyePopLeftFx;
	default EyePopLeftFx.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	UNiagaraComponent EyePopRightFx;
	default EyePopRightFx.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Neck)
	UNiagaraComponent HeadCutFx;
	default HeadCutFx.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UIslandOverseerHaymakerComponent HaymakerComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerLaserAttackComponent LaserAttackComp;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0, AttachSocket=Head)
	USphereComponent HeadPlayerCollision;
	default HeadPlayerCollision.CollisionProfileName = CollisionProfile::NoCollision;

	// Phases
	UPROPERTY()
	FIslandOverseerPhaseChangeEvent OnPhaseChange;
	UPROPERTY()
	FIslandOverseerIntroCombatPhaseStartEvent OnIntroCombatPhaseStart;
	UPROPERTY()
	FIslandOverseerIntroCombatPhaseStartEvent OnIntroCombatPhaseStop;
	UPROPERTY()
	FIslandOverseerFloodPhaseStartEvent OnFloodPhaseStart;
	UPROPERTY()
	FIslandOverseerFloodPhaseStartEvent OnFloodPhaseStop;
	UPROPERTY()
	FIslandOverseerPovCombatPhaseStartEvent OnPovCombatPhaseStart;
	UPROPERTY()
	FIslandOverseerPovCombatPhaseStartEvent OnPovCombatPhaseStop;
	UPROPERTY()
	FIslandOverseerSideChasePhaseStartEvent OnSideChasePhaseStart;
	UPROPERTY()
	FIslandOverseerSideChasePhaseStartEvent OnSideChasePhaseStop;
	UPROPERTY()
	FIslandOverseerTowardsChasePhaseStartEvent OnTowardsChasePhaseStart;
	UPROPERTY()
	FIslandOverseerTowardsChasePhaseStartEvent OnTowardsChasePhaseStop;
	UPROPERTY()
	FIslandOverseerDoorPhaseStartEvent OnDoorPhaseStart;
	UPROPERTY()
	FIslandOverseerDoorPhaseStartEvent OnDoorPhaseStop;
	UPROPERTY()
	FIslandOverseerDoorCutHeadPhaseStartEvent OnDoorCutHeadPhaseStart;
	UPROPERTY()
	FIslandOverseerDoorCutHeadPhaseStartEvent OnDoorCutHeadPhaseStop;
	UPROPERTY()
	FIslandOverseerDeadPhaseStartEvent OnDeadPhaseStart;
	UPROPERTY()
	FIslandOverseerDeadPhaseStartEvent OnDeadPhaseStop;

	// Misc
	UPROPERTY()
	FIslandOverseerFloodStartedEvent OnFloodStarted;
	UPROPERTY()
	FIslandOverseerFloodStoppedEvent OnFloodStopped;
	UPROPERTY()
	FIslandOverseerSideChaseArrivedEvent OnSideChaseArrived;
	UPROPERTY()
	FIslandOverseerIntroCombatHalfHealthEvent OnIntroCombatHalfHealth;
	UPROPERTY()
	FIslandOverseerCutHeadStartEvent OnCutHeadStart;
	UPROPERTY()
	FIslandOverseerCutHeadSuccessEvent OnCutHeadSuccess;
	UPROPERTY()
	FIslandOverseerCutHeadStartEvent OnDoorDefeated;
	UPROPERTY()
	FIslandOverseerCutHeadStartEvent OnSideToTowardsChaseTransition;

	UPROPERTY()
	bool bTriggeredHalfHealth;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp.OnDie.AddUFunction(this, n"OnDeath");
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnDamage");

		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
		UBasicAIHealthBarSettings::SetHealthBarSegments(this, 3, this);
		HealthBarComp.SetHealthBarEnabled(false);

		PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");

		AddActorDisable(this);

		SideChaseComp.OnArrived.AddUFunction(this, n"SideChaseArrived");

		UMovementGravitySettings::SetGravityScale(this, 0, this);

		OnDeadPhaseStart.AddUFunction(this, n"DeadPhaseStart");
	}

	UFUNCTION()
	private void DeadPhaseStart()
	{
		// UMaterialInterface EmptyMaterial = Mesh.GetMaterial(1);
		// Mesh.SetMaterial(5, EmptyMaterial);
		// Mesh.SetMaterial(11, EmptyMaterial);
	}

	UFUNCTION()
	private void SideChaseArrived()
	{
		OnSideChaseArrived.Broadcast();
	}

	UFUNCTION()
	private void PhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		OnPhaseChange.Broadcast(NewPhase, OldPhase);

		if(OldPhase == EIslandOverseerPhase::IntroCombat)
			OnIntroCombatPhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::Flood)
			OnFloodPhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::PovCombat)
			OnPovCombatPhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::SideChase)
			OnSideChasePhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::TowardsChase)
			OnTowardsChasePhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::Door)
			OnDoorPhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::DoorCutHead)
			OnDoorCutHeadPhaseStop.Broadcast();
		if(OldPhase == EIslandOverseerPhase::Dead)
			OnDeadPhaseStop.Broadcast();	

		HealthBarComp.SetHealthBarEnabled(true);

		if(NewPhase == EIslandOverseerPhase::IntroCombat)
		{
			OnIntroCombatPhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(IntroCombatSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::Flood)
		{
			HealthComp.SetCurrentHealth(PhaseComp.IntroCombatHealthThreshold);
			HealthBarComp.SnapBarToHealth();
			OnFloodPhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(FloodSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::PovCombat)
		{
			HealthComp.SetCurrentHealth(PhaseComp.IntroCombatHealthThreshold);
			HealthBarComp.SnapBarToHealth();
			OnPovCombatPhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(PovSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::SideChase)
		{
			HealthComp.SetCurrentHealth(PhaseComp.PovCombatHealthThreshold);
			HealthBarComp.SnapBarToHealth();
			OnSideChasePhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(SideChaseSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::TowardsChase)
		{
			OnTowardsChasePhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(TowardsChaseSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::Door)
		{
			OnDoorPhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(DoorSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::DoorCutHead)
		{
			OnDoorCutHeadPhaseStart.Broadcast();
			SpotLightComp.SetSpotLight(DoorCutHeadSpotLight);
		}
		if(NewPhase == EIslandOverseerPhase::Dead)
			OnDeadPhaseStart.Broadcast();
	}

	UFUNCTION()
	void SetHealth(float Health)
	{
		HealthBarComp.SetHealthBarEnabled(true);
		if(HasControl())
			CrumbSetHealth(Health);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetHealth(float NewHealth)
	{
		HealthComp.SetCurrentHealth(NewHealth);
	}

    UFUNCTION(NotBlueprintCallable)
    private void OnDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType Type)
    {
		if(PhaseComp.Phase != EIslandOverseerPhase::IntroCombat)
			return;

		if(HealthComp.CurrentHealth <= PhaseComp.IntroCombatHalfHealthThreshold && !bTriggeredHalfHealth)
		{
			bTriggeredHalfHealth = true;
			OnIntroCombatHalfHealth.Broadcast();
		}
    }

    UFUNCTION(NotBlueprintCallable)
    private void OnDeath(AHazeActor ActorBeingKilled)
    {
		OnDie();
    }

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDie()
	{
		OnAIDie.Broadcast();
	}
	
	UFUNCTION(BlueprintCallable)
	void BlockBehaviour(FInstigator Instigator)
	{
		BlockCapabilities(BasicAITags::Behaviour, Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void UnblockBehaviour(FInstigator Instigator)
	{
		UnblockCapabilities(BasicAITags::Behaviour, Instigator);
	}

	UFUNCTION()
	void HideHead()
	{
		Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
	}

	UFUNCTION(DevFunction)
	void TogglePeekAttack()
	{
		ToggleTag(n"Peek");
	}

	UFUNCTION(DevFunction)
	void ToggleRollerAttack()
	{
		ToggleTag(n"Roller");
	}

	UFUNCTION(DevFunction)
	void ToggleEyeAttack()
	{
		ToggleTag(n"Eye");
	}

	private void ToggleTag(FName Tag)
	{
		if(IsCapabilityTagBlocked(Tag))
			UnblockCapabilities(Tag, this);
		else
			BlockCapabilities(Tag, this);
	}
}