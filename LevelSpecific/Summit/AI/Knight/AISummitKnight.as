event void FSummitKnightSmashFloorEvent();
event void FSummitKnightDragonRolledUpSwordEvent();
event void FSummitKnightHeadSmashedByDragon();
event void FSummitKnightCoreDestroyed();

UCLASS(Abstract, meta = (DefaultActorLabel = "Knight"))
class AAISummitKnight : ABasicAICharacter
{
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

	default CapabilityComp.DefaultCapabilities.Add(n"AISummitMeltCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileStartIntroCompoundCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileStartLoopCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileCirclingCompoundCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileMainTrackingFlamesCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileMainHomingFireballsCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileEndCirclingCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileEndRunCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileAlmostDeadCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightDashAfterDeathTutorialCapability");
	
	// Damage
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileTakeDamageCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMeltHelmetCapability");

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USummitKnightHeadComponent Head;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USummitKnightHelmetComponent Helmet;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine2")
	UTeenDragonAcidAutoAimComponent AcidAutoAimComp;
	default AcidAutoAimComp.MaximumDistance = 5000.0;

	UPROPERTY(DefaultComponent, Attach = "Head")
	UTeenDragonRollAutoAimComponent HeadRollAutoAimComp;
	default HeadRollAutoAimComp.MaxRange = 4000.0;
	default HeadRollAutoAimComp.MaxDegreesAllowed = 90.0;
	default HeadRollAutoAimComp.bHomingRequireJump = false;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent HeadRollResponseComp;
	default HeadRollResponseComp.bShouldStopPlayer = true;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftAttach")
	USummitKnightCritterSummoningLaunchComponent SummonCrittersLaunchComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;

	UPROPERTY(DefaultComponent)
	USummitKnightComponent KnightComp;

	UPROPERTY(DefaultComponent)
	USummitKnightAnimationComponent KnightAnimationComp;

	UPROPERTY(DefaultComponent)
	USummitKnightStageComponent StageComp;

	UPROPERTY(DefaultComponent, EditAnywhere)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.InitialStoppedSheets_Zoe.Add(SummitKnightRequestSheetZoe);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	USummitKnightSceptreComponent Sceptre;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	USummitKnightBladeComponent RightBlade;
	default RightBlade.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftAttach")
	USummitKnightBladeComponent LeftBlade;
	default LeftBlade.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = "RightBlade")
	USummitKnightGenericAttackShockwaveLauncher RightBladeShockwaveLauncher;

	UPROPERTY(DefaultComponent, Attach = "LeftBlade")
	USummitKnightGenericAttackShockwaveLauncher LeftBladeShockwaveLauncher;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USummitKnightSpinningSlashShockwaveLauncher SpinningSlashShockwaveLauncher;

	UPROPERTY(DefaultComponent, Attach = "Sceptre")
	USceneComponent SceptreLaunchPoint;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftAttach")
	USummitKnightHomingFireballsLauncher HomingFireballsLauncher;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftAttach")
	USummitKnightAreaDenialFireballLauncher AreaDenialFireballLauncher;

	UPROPERTY(DefaultComponent, Attach = "SceptreLaunchPoint")
	USummitKnightFlailComponent Flail;

	UPROPERTY(DefaultComponent, Attach = "Flail")
	UCableComponent FlailChain;
	default FlailChain.CableGravityScale = 0.5;
	default FlailChain.CableLength = 10.0;

	UPROPERTY(DefaultComponent, Attach = "Flail")
	USummitKnightFlailBombLauncher FlailBombLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightRotatingCrystalLauncher RotatingCrystalLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalWallLauncher CrystalWallLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightMetalWallLauncher MetalWallLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalTrailLauncher CrystalTrailLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalDividerLauncher	CrystalDividerLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightCrystalCageLauncher CrystalCageLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightShockwaveLauncher ShockwaveLauncher;

	UPROPERTY(DefaultComponent)
	USummitKnightMobileCrystalBottom CrystalBottom;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(VisibleAnywhere)
	FSummitKnightCoreDestroyed OnCoreDestroyed;

	UPROPERTY(VisibleAnywhere)
	FSummitKnightSmashFloorEvent OnSmashArenaFloor;

	UPROPERTY(VisibleAnywhere)
	FSummitKnightDragonRolledUpSwordEvent OnDragonRolledUpSword;

	UPROPERTY(VisibleAnywhere)
	FSummitKnightHeadSmashedByDragon OnHeadDamagedByDragon;

	UPROPERTY(VisibleAnywhere)
	FSummitKnightHeadSmashedByDragon OnHeadSmashedByDragon;

	UPROPERTY(VisibleAnywhere)
	FKnightChangePhaseSignature OnChangePhase;

	USummitKnightSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Settings = USummitKnightSettings::GetSettings(this);
		HealthComp.OnDie.AddUFunction(this, n"OnDieEvent");
		StageComp.OnChangePhase.AddUFunction(this, n"OnPhaseChange");

		RightBlade.Equip();
		LeftBlade.Unequip();
		Sceptre.Unequip();

		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector(0,0,800), this);
		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
		UBasicAIHealthBarSettings::SetHealthBarSegments(this, 3, this, EHazeSettingsPriority::Gameplay);

		// Zoe will interact most directly with us
		SetActorControlSide(Game::Zoe);
		TargetingComponent.SetTarget(Game::Zoe);
	}

	UFUNCTION()
	private void OnPhaseChange(ESummitKnightPhase NewPhase)
	{
		OnChangePhase.Broadcast(NewPhase);
	}

	UFUNCTION(BlueprintPure)
	ESummitKnightPhase GetPhase() const
	{
		return StageComp.Phase;
	}

	UFUNCTION()
	private void OnDieEvent(AHazeActor ActorBeingKilled)
	{
	}

	UFUNCTION()
	void TeleportToArenaCenter()
	{
		TeleportActor(KnightComp.Arena.Center, ActorRotation, this);
	}

	UFUNCTION()
	void TeleportToMainStartLocation()
	{
		TeleportActor(KnightComp.Arena.SwoopDestination3.WorldLocation, ActorRotation, this);
	}

	UFUNCTION(BlueprintPure)
	bool TestShouldCrystalCoreBeDestroyed()
	{
		if (StageComp.Phase == ESummitKnightPhase::FinalArenaStart)
			return true;
		if ((StageComp.Phase == ESummitKnightPhase::CrystalCoreDamage) && (StageComp.Round > 1))
			return true;
		return false;
	}

	UFUNCTION(DevFunction)
	void StartInitial()
	{
		TeleportToArenaCenter();
		StageComp.SetPhase(ESummitKnightPhase::MobileStart, 0);
		CrystalBottom.Retract(this);
		CrystalBottom.Deploy(this);
	}

	UFUNCTION(DevFunction)
	void StartCircling()
	{
		TeleportToArenaCenter();
		StageComp.SetPhase(ESummitKnightPhase::MobileCircling, 0);
		HealthComp.SetCurrentHealth(Settings.HealthThresholdStartToCircling);
		KnightComp.NumberOfSwoops = 3;
	}

	UFUNCTION(DevFunction)
	void StartMainAttackLoop()
	{
		TeleportToMainStartLocation();
		StageComp.SetPhase(ESummitKnightPhase::MobileMain, 0);
		CrystalBottom.Retract(this);
		CrystalBottom.Deploy(this);
		HealthComp.SetCurrentHealth(Settings.HealthThresholdStartToCircling);
		KnightComp.NumberOfSwoops = 3;
	}

	UFUNCTION(DevFunction)
	void StartEndCircling()
	{
		TeleportToArenaCenter();
		StageComp.SetPhase(ESummitKnightPhase::MobileEndCircling, 0);
		HealthComp.SetCurrentHealth(Settings.HealthThresholdMainToEndCircling);
		KnightComp.NumberOfSwoops = 10;
	}

	UFUNCTION(DevFunction)
	void StartEndRun()
	{
		TeleportToMainStartLocation();
		StageComp.SetPhase(ESummitKnightPhase::MobileEndRun, 0);
		HealthComp.SetCurrentHealth(Settings.HealthThresholdMainToEndCircling);
		KnightComp.NumberOfSwoops = 10;
		CrystalBottom.Retract(this);
		CrystalBottom.Deploy(this);
	}

	UFUNCTION(DevFunction, Meta = (Deprecated))
	void Phase2_1()
	{
		StartMainAttackLoop();
	}

	UFUNCTION(DevFunction)
	void Kill()
	{
		// Head will be destroyed!
		StageComp.SetPhase(ESummitKnightPhase::HeadDamage, 2);
		OnHeadSmashedByDragon.Broadcast();
	}

	// Test stuff
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightMobileTestCompoundCapability");
}

asset SummitKnightRequestSheetZoe of UHazeCapabilitySheet
{
	Capabilities.Add(USummitKnightPlayerJumpToHeadCapability);
	Capabilities.Add(USummitKnightPlayerRollToHeadCapability);
	Components.Add(USummitKnightPlayerRollToHeadComponent);
}

namespace SummitKnightTags
{
	const FName SummitKnightTeam = n"SummitKnightTeam";
	const FName SummitKnightShield = n"SummitKnightShield";
	const FName SummitKnightShieldBlocking = n"SummitKnightShieldBlocking";
}