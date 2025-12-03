event void FIslandWalkerPhaseChangeSignature(EIslandWalkerPhase NewPhase);
event void FISlandWalkerSkipIntroSignature();

UCLASS(Abstract)
class AAIIslandWalker : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerDeathCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerIntroCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerWalkingCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerSuspendedBehaviourCompoundCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"HazeActorSpawnerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerUnderneathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerGroundMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerSuspendedMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerSuspensionCableUpdateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerSuspendedSlowdownCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerNeckPanelEnablingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerRespawnPointsCapability");


	UPROPERTY(DefaultComponent)
	UIslandWalkerAnimationComponent WalkerAnimComp;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnerComponent SpawnerComp;
	default SpawnerComp.bStartActivated = true;

	UPROPERTY(DefaultComponent)
	UIslandWalkerSpawnPattern SpawnPattern;
	default SpawnPattern.bStartActive = false;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "LeftFrontWingExhaust")
	UWalkerSpawnPointComponent SpawnPoint0;
	default SpawnPoint0.Index = 0;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "LeftMiddleWingExhaust")
	UWalkerSpawnPointComponent SpawnPoint1;
	default SpawnPoint1.Index = 1;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "LeftBackWingExhaust")
	UWalkerSpawnPointComponent SpawnPoint2;
	default SpawnPoint2.Index = 2;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "RightFrontWingExhaust")
	UWalkerSpawnPointComponent SpawnPoint3;
	default SpawnPoint3.Index = 3;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "RightMiddleWingExhaust")
	UWalkerSpawnPointComponent SpawnPoint4;
	default SpawnPoint4.Index = 4;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "RightBackWingExhaust")
	UWalkerSpawnPointComponent SpawnPoint5;
	default SpawnPoint5.Index = 5;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "LeftFrontWingExhaust")
	UIslandWalkerClusterMineLauncherComponent MineLauncher0;
	default MineLauncher0.Index = 0;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "LeftMiddleWingExhaust")
	UIslandWalkerClusterMineLauncherComponent MineLauncher1;
	default MineLauncher1.Index = 1;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "LeftBackWingExhaust")
	UIslandWalkerClusterMineLauncherComponent MineLauncher2;
	default MineLauncher2.Index = 2;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "RightFrontWingExhaust")
	UIslandWalkerClusterMineLauncherComponent MineLauncher3;
	default MineLauncher3.Index = 3;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "RightMiddleWingExhaust")
	UIslandWalkerClusterMineLauncherComponent MineLauncher4;
	default MineLauncher4.Index = 4;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket = "RightBackWingExhaust")
	UIslandWalkerClusterMineLauncherComponent MineLauncher5;
	default MineLauncher5.Index = 5;

	UPROPERTY(DefaultComponent)
	UIslandWalkerLegsComponent LegsComp;

	UPROPERTY(DefaultComponent)
	UIslandWalkerUnderneathComponent UnderneathComp;

	UPROPERTY(DefaultComponent)
	UIslandWalkerComponent WalkerComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilities.Add(n"IslandWalkerPlayerSlowedAirMotionCapability");
	default RequestCapabilityComp.PlayerCapabilities.Add(n"IslandWalkerHeadHatchInteractionCapability");

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Hips")
	UCapsuleComponent BodyCollision;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Hips")
	UCapsuleComponent BodyRepulsion;

	UPROPERTY(DefaultComponent)
	UIslandWalkerPhaseComponent PhaseComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "SpineBase")
	UIslandWalkerSwivelComponent SwivelComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFrontLeg_MioHitLocation_Socket")
	UIslandWalkerLegRoot LeftLeg0;	
	default LeftLeg0.RelativeLocation = FVector(0.0, 0.0, 80.0); 
	default LeftLeg0.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default LeftLeg0.BluePanelSocket = n"LeftFrontLeg_ZoeHitLocation_Socket";
	default LeftLeg0.RedPanelSocket = n"LeftFrontLeg_MioHitLocation_Socket";
	default LeftLeg0.CoverPanelSocket = n"LeftFrontLeg_CoverSocket";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFrontMiddleLeg_MioHitLocation_Socket")	
	UIslandWalkerLegRoot LeftLeg1;	
	default LeftLeg1.RelativeLocation = FVector(0.0, 0.0, -80.0); 
	default LeftLeg1.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default LeftLeg1.HatchAnimType = EWalkerHatch::FrontLeft;
	default LeftLeg1.BluePanelSocket = n"LeftFrontMiddleLeg_ZoeHitLocation_Socket";
	default LeftLeg1.RedPanelSocket = n"LeftFrontMiddleLeg_MioHitLocation_Socket";
	default LeftLeg1.CoverPanelSocket = n"LeftFrontMiddleLeg_CoverSocket";
	default LeftLeg1.ForceFieldAttachSocket = n"LeftFrontMiddleLeg3";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftBackMiddleLeg_MioHitLocation_Socket")
	UIslandWalkerLegRoot LeftLeg2;	
	default LeftLeg2.RelativeLocation = FVector(0.0, 0.0, 80.0); 
	default LeftLeg2.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default LeftLeg2.HatchAnimType = EWalkerHatch::RearLeft;
	default LeftLeg2.BluePanelSocket = n"LeftBackMiddleLeg_ZoeHitLocation_Socket";
	default LeftLeg2.RedPanelSocket = n"LeftBackMiddleLeg_MioHitLocation_Socket";
	default LeftLeg2.CoverPanelSocket = n"LeftBackMiddleLeg_CoverSocket";
	default LeftLeg2.ForceFieldAttachSocket = n"LeftBackMiddleLeg4";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftBackLeg_MioHitLocation_Socket")
	UIslandWalkerLegRoot LeftLeg3;	
	default LeftLeg3.RelativeLocation = FVector(0.0, 0.0, -80.0); 
	default LeftLeg3.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default LeftLeg3.BluePanelSocket = n"LeftBackLeg_ZoeHitLocation_Socket";
	default LeftLeg3.RedPanelSocket = n"LeftBackLeg_MioHitLocation_Socket";
	default LeftLeg3.CoverPanelSocket = n"LeftBackLeg_CoverSocket";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFrontLeg_MioHitLocation_Socket")
	UIslandWalkerLegRoot RightLeg0;	
	default RightLeg0.RelativeLocation = FVector(0.0, 0.0, 80.0); 
	default RightLeg0.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default RightLeg0.BluePanelSocket = n"RightFrontLeg_ZoeHitLocation_Socket";
	default RightLeg0.RedPanelSocket = n"RightFrontLeg_MioHitLocation_Socket";
	default RightLeg0.CoverPanelSocket = n"RightFrontLeg_CoverSocket";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFrontMiddleLeg_MioHitLocation_Socket")	
	UIslandWalkerLegRoot RightLeg1;	
	default RightLeg1.RelativeLocation = FVector(0.0, 0.0, -80.0); 
	default RightLeg1.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default RightLeg1.HatchAnimType = EWalkerHatch::FrontRight;
	default RightLeg1.BluePanelSocket = n"RightFrontMiddleLeg_ZoeHitLocation_Socket";
	default RightLeg1.RedPanelSocket = n"RightFrontMiddleLeg_MioHitLocation_Socket";
	default RightLeg1.CoverPanelSocket = n"RightFrontMiddleLeg_CoverSocket";
	default RightLeg1.ForceFieldAttachSocket = n"RightFrontMiddleLeg3";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightBackMiddleLeg_MioHitLocation_Socket")
	UIslandWalkerLegRoot RightLeg2;	
	default RightLeg2.RelativeLocation = FVector(0.0, 0.0, 80.0); 
	default RightLeg2.RelativeRotation = FRotator(180.0, 0.0, 0.0);	
	default RightLeg2.HatchAnimType = EWalkerHatch::RearRight;
	default RightLeg2.BluePanelSocket = n"RightBackMiddleLeg_ZoeHitLocation_Socket";
	default RightLeg2.RedPanelSocket = n"RightBackMiddleLeg_MioHitLocation_Socket";
	default RightLeg2.CoverPanelSocket = n"RightBackMiddleLeg_CoverSocket";
	default RightLeg2.ForceFieldAttachSocket = n"RightBackMiddleLeg4";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightBackLeg_MioHitLocation_Socket")
	UIslandWalkerLegRoot RightLeg3;	
	default RightLeg3.RelativeLocation = FVector(0.0, 0.0, -80.0); 
	default RightLeg3.RelativeRotation = FRotator(0.0, 0.0, 0.0);	
	default RightLeg3.BluePanelSocket = n"RightBackLeg_ZoeHitLocation_Socket";
	default RightLeg3.RedPanelSocket = n"RightBackLeg_MioHitLocation_Socket";
	default RightLeg3.CoverPanelSocket = n"RightBackLeg_CoverSocket";

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket="Spine1")
	UIslandWalkerCablesTargetRoot FrontCablesTargetRoot;	
	default FrontCablesTargetRoot.RelativeLocation = FVector(380.0, 0.0, 150.0);
	default FrontCablesTargetRoot.ForceFieldType = EIslandForceFieldType::Red;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket="Tail2")
	UIslandWalkerCablesTargetRoot RearCablesTargetRoot;	
	default RearCablesTargetRoot.RelativeLocation = FVector(380.0, 0.0, 0.0);
	default RearCablesTargetRoot.ForceFieldType = EIslandForceFieldType::Blue;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket="Head")
	UIslandWalkerNeckRoot NeckRoot;	

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket="NeckHitTarget")
	UIslandWalkerNeckCoverRoot NeckCover;

	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket="Head")
	UIslandWalkerCableOriginComponent NeckCableOrigin;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueReflectComponent BulletReflectorComp;

	UPROPERTY(DefaultComponent)
	UIslandWalkerShellCasingsLauncher ShellCasingsLauncher;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFrontLeg5")
	UIslandWalkerStompComponent LeftFrontStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFrontMiddleLeg5")
	UIslandWalkerStompComponent LeftFrontMiddleStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftBackMiddleLeg6")
	UIslandWalkerStompComponent LeftBackMiddleStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftBackLeg6")
	UIslandWalkerStompComponent LeftBackStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFrontLeg5")
	UIslandWalkerStompComponent RightFrontStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFrontMiddleLeg5")
	UIslandWalkerStompComponent RightFrontMiddleStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightBackMiddleLeg6")
	UIslandWalkerStompComponent RightBackMiddleStompComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightBackLeg6")
	UIslandWalkerStompComponent RightBackStompComp;	
	
	UPROPERTY(DefaultComponent)
    UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazePhysicalAnimationComponent PhysicalAnimComp;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	TArray<FSoundDefReference> WalkerHeadSoundDefs;

	UPROPERTY()
	FIslandWalkerPhaseChangeSignature OnPhaseChange;

	UPROPERTY()
	FISlandWalkerSkipIntroSignature OnSkipIntro;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		this.JoinTeam(IslandWalkerTags::IslandWalkerTeam);
		UPathfollowingSettings::SetIgnorePathfinding(this, true, this);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		
		SetupLegs();
		NeckRoot.SetupHead();
		NeckRoot.SetupTarget();
		NeckRoot.NeckTarget.PowerDown();
		FrontCablesTargetRoot.SetupTarget();
		FrontCablesTargetRoot.Target.PowerDown();
		RearCablesTargetRoot.SetupTarget();
		RearCablesTargetRoot.Target.PowerDown();

		WalkerComp.Laser = NeckRoot.Head.Laser;
		ShellCasingsLauncher.AttachTo(WalkerComp.Laser, NAME_None, EAttachLocation::KeepRelativeOffset);

		BodyRepulsion.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");

		TListedActors<AIslandWalkerArenaLimits> Arenas;
		if (ensure(Arenas.Num() > 0))
		{
			WalkerComp.ArenaLimits = Arenas[0];
			ShellCasingsLauncher.ArenaHeight = WalkerComp.ArenaLimits.Height + 20.0;
		}
	}

	UFUNCTION(BlueprintPure)
	AIslandWalkerHead GetHead() const
	{
		return NeckRoot.Head;
	} 

	UFUNCTION(BlueprintPure)
	AIslandWalkerCablesTarget GetFrontCablesTarget() const
	{
		return FrontCablesTargetRoot.Target;
	} 

	UFUNCTION(BlueprintPure)
	AIslandWalkerCablesTarget GetRearCablesTarget() const
	{
		return RearCablesTargetRoot.Target;
	} 

	UFUNCTION()
	private void PhaseChange(EIslandWalkerPhase NewPhase)
	{
		OnPhaseChange.Broadcast(NewPhase);
		WalkerComp.ArenaLimits.OnPhaseChange.Broadcast(NewPhase);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Game::Mio.ClearSettingsByInstigator(this);			
		Game::Zoe.ClearSettingsByInstigator(this);			
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		FStumble Stumble;
		Stumble.Move = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * 2000;
		Stumble.Duration = 1;
		Player.ApplyStumble(Stumble);
	}

	void SetupLegs()
	{
		TArray<UIslandWalkerLegRoot> Legs;
		GetComponentsByClass(Legs);

		TArray<UShapeComponent> Collisions;
		Mesh.GetChildrenComponentsByClass(UShapeComponent, true, Collisions);

		for (UIslandWalkerLegRoot Leg : Legs)
		{
			Leg.SetupTarget(LegsComp);
		}
	}

	float DeathTime;
	float DeathDuration = 2.5;

	void PowerDown()
	{
		LegsComp.PowerDownLegs();
	}

	void PowerUp()
	{
		LegsComp.PowerUpLegs();
	}

	UFUNCTION()
	private void OnReset()
	{
		SetActorRotation(FRotator());
		LegsComp.Reset();
		DeathTime = 0;
	}

	UFUNCTION(DevFunction)
	void TestDestroyLegs()
	{
		if (PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return;

		// Destroy some legs
		if (!HasControl())
			return;

		for (AIslandWalkerLegTarget Leg : LegsComp.LegTargets)
		{
			if (Leg.bIsDestroyed)
				continue;
			Leg.CrumbDestroyLeg();			
			break;
		}				
	}

	UFUNCTION(DevFunction)
	void TestDestroyCables()
	{
		if (PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return;
	
		if (FrontCablesTargetRoot.Target == nullptr)
			return;

		if (!FrontCablesTargetRoot.Target.bCablesTargetDestroyed)
		{
			if (HasControl())
				FrontCablesTargetRoot.Target.CrumbDestroy();	
			return;
		}			
		if (!RearCablesTargetRoot.Target.bCablesTargetDestroyed)
		{
			if (HasControl())
				RearCablesTargetRoot.Target.CrumbDestroy();	
			return;
		}			
	}

	// UFUNCTION(DevFunction, NotBlueprintCallable)
	// void TestDestroyNeck()
	// {
	// 	if (NeckRoot.Head.HeadComp.State == EIslandWalkerHeadState::Detached)
	// 		return; 

	// 	if (NeckRoot.Head.HeadComp.State == EIslandWalkerHeadState::Attached)
	// 	{
	// 		// Fall first, destroy neck later
	// 		TestDestroyLegs();
	// 		Timer::SetTimer(this, n"TestDestroyNeck", 8.0);
	// 		return;
	// 	}

	// 	NeckRoot.NeckTarget.ShootablePanel.OnOvercharged.Broadcast();		
	// }

	UFUNCTION()
	void WakeUp()
	{
		if (PhaseComp.Phase == EIslandWalkerPhase::Intro)
		{
			PhaseComp.Phase = EIslandWalkerPhase::IntroEnd;
		}
	}

	UFUNCTION(DevFunction)
	void PostSuspendedCutscene()
	{
		PhaseComp.Phase = EIslandWalkerPhase::Suspended;
		PhaseComp.SkipIntro();
		PhysicalAnimComp.ClearDisable(PhysicalAnimComp);
	}

	UFUNCTION(DevFunction)
	void SkipToPhase2()
	{
		if (PhaseComp.Phase < EIslandWalkerPhase::Suspended)
		{
			PhaseComp.Phase = EIslandWalkerPhase::Suspended;
			PhaseComp.SkipIntro();
		}
	}

	UFUNCTION(DevFunction)
	void PostFallIntoAcidCutscene()
	{
		if (!IsActorDisabledBy(this))
			AddActorDisable(this);
	}

	UFUNCTION(DevFunction)
	void SkipToPhase3()
	{
		if (PhaseComp.Phase < EIslandWalkerPhase::Decapitated)
		{
			PhaseComp.Phase = EIslandWalkerPhase::Decapitated;
			PhaseComp.SkipIntro();
			if (!IsActorDisabledBy(this))
				AddActorDisable(this);
		}
	}

	UFUNCTION(DevFunction)
	void SkipToPhase4()
	{
		if (PhaseComp.Phase < EIslandWalkerPhase::Swimming)
		{
			PhaseComp.Phase = EIslandWalkerPhase::Swimming;
			PhaseComp.SkipIntro();
			if (!IsActorDisabledBy(this))
				AddActorDisable(this);
		}
	}

	UFUNCTION(DevFunction)
	void SkipIntro()
	{
		if (PhaseComp.Phase == EIslandWalkerPhase::Intro)
		{
			PhaseComp.Phase = EIslandWalkerPhase::Walking;
			PhaseComp.SkipIntro();
			OnSkipIntro.Broadcast();
		}
	}

	UFUNCTION()
	void SmashHeadHealthBar(float RemainingSmashHealthFraction)
	{
		if (NeckRoot.Head == nullptr)
			return;
		if (NeckRoot.Head.StumpRoot.Target == nullptr)
			return;
		
		// Health bar only 
		UWalkerHeadStumpTargetHealthBarComponent HealthBar = UWalkerHeadStumpTargetHealthBarComponent::Get(NeckRoot.Head.StumpRoot.Target);
		if (HealthBar == nullptr)
			return;
		HealthBar.ModifySmashHealth(RemainingSmashHealthFraction);
	}
}

class AIslandWalkerAttachmentPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(3.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 150.0);
#endif	

	UPROPERTY(EditAnywhere)
	int Slot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(IslandWalkerTags::IslandWalkerAttachmentTeam);
	}
}

class AIslandWalkerExposedTeleportPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(3.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 150.0);
#endif	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(IslandWalkerTags::IslandWalkerExposedTeleportTeam);
	}
}

namespace IslandWalkerTags
{
	const FName IslandWalkerTeam = n"IslandWalkerTeam";
	const FName IslandWalkerSuspendTeam = n"IslandWalkerSuspendTeam";
	const FName IslandWalkerAttachmentTeam = n"IslandWalkerAttachmentTeam";
	const FName IslandWalkerExposedTeleportTeam = n"IslandWalkerExposedTeleportTeam";
}

namespace WalkerBoss
{
	UFUNCTION(Category = "VFX", DisplayName = "Get Walker Boss")
	AAIIslandWalker Get()
	{
		AAIIslandWalker WalkerBoss = TListedActors<AAIIslandWalker>().GetSingle();
		return WalkerBoss;
	}
}


