UCLASS(Abstract)
class AAIIslandPunchotron : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronElevatorBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIMatchTargetControlSideCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronGroundMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronWheelchairMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAITeleportAlongRuntimeSplineCapabability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronDamagePlayerOnTouchCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronPanelLingerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronElevatorFallThroughHoleCapability");
	

	UPROPERTY(DefaultComponent, AttachSocket="Hips")
	UHazeCapsuleCollisionComponent BulletCollisionCapsuleComponent;
	default BulletCollisionCapsuleComponent.bGenerateOverlapEvents = false;
	default BulletCollisionCapsuleComponent.CollisionProfileName = n"NoCollision";
	default BulletCollisionCapsuleComponent.CollisionObjectType = ECollisionChannel::EnemyCharacter;
	default BulletCollisionCapsuleComponent.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BulletCollisionCapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Block);
	default BulletCollisionCapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default BulletCollisionCapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default BulletCollisionCapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default BulletCollisionCapsuleComponent.CapsuleHalfHeight = 150.0;
	default BulletCollisionCapsuleComponent.CapsuleRadius = 100.0;
	default BulletCollisionCapsuleComponent.SetRelativeLocation(FVector(15,0,200));


	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Ignore);
	default CapsuleComponent.CapsuleHalfHeight = 150.0;
	default CapsuleComponent.CapsuleRadius = 125.0;
	default CapsuleComponent.SetRelativeLocation(FVector(0,0,150));



	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.SetRelativeLocation(FVector(0,0,75.0));

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueImpactResponseComponent DamageResponseComp;
	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;
	
	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerKnockdownSheet); // Replace this with a sheet containing animations in BP
#if EDITOR
	default RequestCapabilityComp.InitialStoppedPlayerCapabilities.Add(n"IslandPunchotronDevTogglesCapability");
#endif

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UIslandForceFieldComponent ForceFieldComp;
	default ForceFieldComp.bIsAutoRespawnable = true;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;
	default ForceFieldCollisionComp.AdditionalCollisionShapeTolerance = 100.0;
	default ForceFieldCollisionComp.bStayIgnoredWhenIgnoredOnce = true;

	UPROPERTY(DefaultComponent)
	UIslandPunchotronFollowSplineComponent FollowSplineComponent;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	USceneComponent EyeTelegraphingLocation;
	default EyeTelegraphingLocation.RelativeLocation = FVector(165.0, 0.0, 42.5);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	USceneComponent ExhaustVentLocation;
	default ExhaustVentLocation.RelativeLocation = FVector(-204.0, 21.0, 135.0);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFoot")
	USceneComponent LeftJetLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFoot")
	USceneComponent RightJetLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFoot")
	USceneComponent LeftFlameThrowerLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFoot")
	USceneComponent RightFlameThrowerLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftForeArm")
	USceneComponent LeftBladeLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightForeArm")
	USceneComponent RightBladeLocation;

	UPROPERTY(DefaultComponent)
	UIslandPunchotronAttackComponent AttackComp;

	// Searchlight decal
	UPROPERTY(DefaultComponent)
	UIslandPunchotronDecalComponent AttackDecalComp;
	default AttackDecalComp.Hide();
	default AttackDecalComp.DecalSize = FVector(128.0, 128.0, 128.0);
	default AttackDecalComp.SetWorldRotation(FRotator(-90.0, 0.0, 0.0));

	// Locked on target decal
	UPROPERTY(DefaultComponent)
	UIslandPunchotronDecalComponent AttackTargetDecalComp;
	default AttackTargetDecalComp.Hide();
	default AttackTargetDecalComp.DecalSize = FVector(128.0, 128.0, 128.0);
	default AttackTargetDecalComp.SetWorldRotation(FRotator(-90.0, 0.0, 0.0));

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	// temp
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AnimationTaunt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplyDefaultSettings(IslandPunchotronHealthBarSettings);

		AttackDecalComp.DetachFromParent(); // Remain at worldlocation
		//AttackTargetDecalComp.DetachFromParent(); // Remain at worldlocation

		UHazeTeam PunchotronTeam = JoinTeam(IslandPunchotronTags::IslandPunchotronTeamTag);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		HealthComp.OnDie.AddUFunction(this, n"OnPunchotronDie");
#if EDITOR
		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::Mio, this);		
#endif

	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
	}

	UFUNCTION()
	private void OnPunchotronDie(AHazeActor ActorBeingKilled)
	{
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(this);
		AttackDecalComp.Hide();
		AttackDecalComp.Reset();
		AttackTargetDecalComp.Hide();
		AttackTargetDecalComp.Reset();
		AttackTargetDecalComp.AttachTo(RootComponent); // might be deattached
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (RespawnComp.SpawnParameters.Spline != nullptr)
			FollowSplineComponent.Spline = RespawnComp.SpawnParameters.Spline;
	}

	UFUNCTION(DevFunction)
	void KnockOut()
	{
	}

}


event void FIslandPunchotronBossForcefieldPreActivateSignature(FVector PunchotronLocation, FRotator PunchotronRotation);

UCLASS(Abstract)
class AAIIslandPunchotronBoss : AAIIslandPunchotron
{
	default CapabilityComp.DefaultCapabilities.Remove(n"IslandPunchotronElevatorBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"IslandPunchotronElevatorFallThroughHoleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronPanelLingerCapability");

	UPROPERTY()
	FIslandPunchotronBossForcefieldPreActivateSignature OnPreForcefieldActivated;

	bool bIsEnableTimerSet = false;
	bool bIsForcefieldEnabled = false;
	bool bIsUnblockTimerSet = false;
	bool bIsUnblocked = false;
	float EnableTimer = 0.0;
	float UnblockTimer = 0.0;

	UIslandPunchotronSettings Settings;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Settings = UIslandPunchotronSettings::GetSettings(this);
		BlockCapabilities(n"IslandForceField", this);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTookDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");

#if EDITOR
		// bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			FHazeDevInputInfo Info;
			Info.Name = n"DevResetForcefieldActivation";
			Info.Category = n"Default";
			Info.OnTriggered.BindUFunction(this, n"Reset");
			Info.AddKey(EKeys::R);
			Game::Mio.RegisterDevInput(Info);
			Game::Zoe.RegisterDevInput(Info);
		}
#endif
	}

	UFUNCTION()
	private void Reset()
	{
		if (!bIsUnblocked && bIsUnblockTimerSet)
		{				
			UnblockPunchotron();
		}

		bIsEnableTimerSet = false;
		bIsForcefieldEnabled = false;
		bIsUnblockTimerSet = false;
		bIsUnblocked = false;
		EnableTimer = 0.0;
		UnblockTimer = 0.0;
		if (!IsCapabilityTagBlocked(n"IslandForceField"))
			BlockCapabilities(n"IslandForceField", this);
	}

	// Will activate shield when reaching health limit
	UFUNCTION()
	private void OnTookDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (!Settings.bIsBossForcefieldCutsceneEnabled)
			return;

		if (bIsEnableTimerSet)
			return;

		if (HealthComp.CurrentHealth < Settings.BossActivateForcefieldHealthLimit)
		{
			EnableTimer = Settings.BossEnableForcefieldInCutsceneTimer;
			bIsEnableTimerSet = true;
			OnPreForcefieldActivated.Broadcast(ActorLocation, ActorRotation);

			BlockPunchotron();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsEnableTimerSet)
			return;
		
		// Countdown for activating forcefield
		EnableTimer -= DeltaSeconds;

		// Temp indicator of shield enabling
		if (EnableTimer > 0.1 && EnableTimer < 0.5)
		{
			DamageFlash::DamageFlashActor(this, 0.5, FLinearColor::LucBlue);
			FHazeSlotAnimSettings Params;
			Params.BlendTime = 0.2;
			Params.BlendOutTime = 0.2;
			Params.bLoop = false;
			Params.StartTime = 0.0;
			Params.PlayRate = 4.0;
			Params.BlendType = EHazeBlendType::BlendType_Inertialization;
			PlaySlotAnimation(AnimationTaunt, Params);
		}		

		if (EnableTimer < 0.0)
		{
			// Enable forcefield and start countdown for ending cutscene.
			if (!bIsForcefieldEnabled)
			{
				UnblockCapabilities(n"IslandForcefield", this);
				bIsUnblockTimerSet = true;
				UnblockTimer = Settings.BossEnableMovementInCutsceneTimer;
			}
			bIsForcefieldEnabled = true;
		}


		if (!bIsUnblockTimerSet)
			return;

		// Countdown for ending cutscene and unblocking movement and input.
		UnblockTimer -= DeltaSeconds;
		if (UnblockTimer < 0.0)
		{
			if (!bIsUnblocked)
			{				
				UnblockPunchotron();
			}
			bIsUnblocked = true;
		}
	}

	// Disable punchotron behaviour
	private void BlockPunchotron()
	{
		//BlockCapabilities(CapabilityTags::Movement, this);
		BlockBehaviour(this);
		// If moving at a high speed when shield is activated, we want to decelerate to a stand still.
		UIslandPunchotronSettings::SetGroundFriction(this, Settings.GroundFriction * 3.0, this, EHazeSettingsPriority::Override);
	}

	private void UnblockPunchotron()
	{
		//UnblockCapabilities(CapabilityTags::Movement, this);
		UnblockBehaviour(this);
		UIslandPunchotronSettings::ClearGroundFriction(this, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION(DevFunction)
	void DevResetForcefieldActivation()	
	{
		Reset();
	}

}

asset IslandPunchotronHealthBarSettings of UBasicAIHealthBarSettings
{
	HealthBarOffset = FVector(0.0, 0.0, 240.0);
}

namespace IslandPunchotronTags
{
	const FName IslandPunchotronTeamTag = n"IslandPunchotronTeam";
}

namespace IslandPunchotronTokens
{
	const FName PunchotronChaseToken = n"PunchotronChaseToken";
}