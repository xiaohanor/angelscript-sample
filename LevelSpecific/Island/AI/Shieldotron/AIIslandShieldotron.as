
UCLASS(Abstract)
class AAIIslandShieldotron : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldBubbleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	// Note: Default behaviour compound is also specified in the BP-class for PilotShieldotron.
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronAggressiveBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronEvasiveBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronJetskiBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronLeapTraversalMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronDamagePlayerOnTouchCapability");


	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ForceFieldBubbleOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldBubbleOffsetComponent")
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UIslandForceFieldComponent ForceFieldComp;	
	default ForceFieldComp.bIsAutoRespawnable = true;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	UBasicAIProjectileLauncherComponent LauncherComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	UIslandShieldotronOrbLauncher OrbLauncherComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent BlastAttackComp;
	default BlastAttackComp.SetRelativeLocation(FVector(41.0 , 0.0, -22.0));

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftForeArm")
	UIslandShieldotronMortarLauncherLeft MortarLauncherLeftComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightForeArm")
	UIslandShieldotronMortarLauncherRight MortarLauncherRightComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftForeArm")
	UIslandShieldotronMissileLauncherLeft MissileLauncherLeftComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightForeArm")
	UIslandShieldotronMissileLauncherRight MissileLauncherRightComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftHand")
	USceneComponent Laser;

	UPROPERTY(DefaultComponent)
	UIslandShieldotronLaserAimingComponent LaserAimingComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;
	
	UPROPERTY(DefaultComponent)
	UBasicAIEntranceComponent EntranceComp;
	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UTrajectoryTraversalComponent TraversalComp;
	default TraversalComp.Methods.Add(UIslandJumpUpTraversalMethod);
	default TraversalComp.Methods.Add(UIslandJumpDownTraversalMethod);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	USceneComponent JumpBoostVFX;

	UPROPERTY(DefaultComponent)
	UIslandShieldotronJumpComponent JumpComp;
	
	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(EditAnywhere)
	UIslandShieldotronSettings DefaultSettings;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"IslandShieldotronDevTogglesCapability");
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		this.JoinTeam(IslandShieldotronTags::IslandShieldotronTeam, UIslandShieldotronTeam);
		UIslandShieldotronSettings Settings = UIslandShieldotronSettings::GetSettings(this);
		EntranceComp.CollisionDurationAtEndOfEntrance.Apply(Settings.CollisionDurationAtEndOfEntrance, this, EInstigatePriority::Low);
		ApplyDefaultSettings(IslandShieldotronHealthBarSettings);
		ApplySettings(IslandShieldotronBasicSettings, this);
		// Override default settings
		if (DefaultSettings != nullptr)
			ApplyDefaultSettings(DefaultSettings);

		ForceFieldComp.AutoRespawnCooldown = Settings.ForceFieldDepletedCooldown;
#if EDITOR
		RequestComp.StartInitialSheetsAndCapabilities(Game::Mio, this);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		this.LeaveTeam(IslandShieldotronTags::IslandShieldotronTeam);
		this.LeaveTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);
		this.LeaveTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 200;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ForceFieldComp.AutoRespawnCooldown = UIslandShieldotronSettings::GetSettings(this).ForceFieldDepletedCooldown;
	}
#endif

}

asset IslandShieldotronHealthBarSettings of UBasicAIHealthBarSettings
{
	HealthBarOffset = FVector(0.0, 0.0, 280.0);
}

asset IslandShieldotronBasicSettings of UBasicAISettings
{
	TrackTargetRange = 15000;
}

namespace IslandShieldotronTags
{
	const FName IslandShieldotronTeam = n"IslandShieldotronTeam";
	const FName IslandShieldotronAggressiveTeam = n"IslandShieldotronAggressiveTeam";
	const FName IslandShieldotronEvasiveTeam = n"IslandShieldotronEvasiveTeam";
}

struct FPlayerTraversalAreaInfo
{
	bool bIsSet = false;
	float LastTraversalAreaUpdate = BIG_NUMBER;
	ATraversalAreaActorBase LastKnownTraversalArea = nullptr;
}
class UIslandShieldotronTeam : UHazeTeam
{	
	TPerPlayer<FPlayerTraversalAreaInfo> PlayerLastKnownTraversalArea;

	void SetPlayersLastKnownArea(AHazePlayerCharacter Player, ATraversalAreaActorBase Area)
	{
		PlayerLastKnownTraversalArea[Player].LastKnownTraversalArea = Area;
		PlayerLastKnownTraversalArea[Player].LastTraversalAreaUpdate = Time::GameTimeSeconds;
		PlayerLastKnownTraversalArea[Player].bIsSet = true;
	}

	TArray<ATraversalAreaActorBase> GetPlayersLastKnownAreas()
	{
		TArray<ATraversalAreaActorBase> Areas;
		for (FPlayerTraversalAreaInfo Info : PlayerLastKnownTraversalArea)
		{
			if (Info.LastKnownTraversalArea != nullptr)
				Areas.AddUnique(Info.LastKnownTraversalArea);
		}
		return Areas;
	}

	FPlayerTraversalAreaInfo GetPlayersLastKnownAreaInfo(AHazePlayerCharacter Player)
	{
		return PlayerLastKnownTraversalArea[Player];		
	}

}

