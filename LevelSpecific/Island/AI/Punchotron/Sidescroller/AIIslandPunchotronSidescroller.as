UCLASS(Abstract)
class AAIIslandPunchotronSidescroller : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronSidescrollerDeathCapability");
	//default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronSidescrollerTakeDamageCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronSidescrollerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronSidescrollerGroundMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SidescrollerGroundPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandPunchotronDamagePlayerOnTouchCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandSidescrollerPunchotronLeapTraversalMovementCapability");

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
	default BulletCollisionCapsuleComponent.CapsuleHalfHeight = 110.0;
	default BulletCollisionCapsuleComponent.CapsuleRadius = 34.0;
	default BulletCollisionCapsuleComponent.SetRelativeLocation(FVector(0,0,110));

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.OptionalShape = FHazeShapeSettings::MakeCapsule(30, 110);
	default TargetableComp.RelativeLocation = FVector(0, 0, 22);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	USceneComponent EyeTelegraphingLocation;
	default EyeTelegraphingLocation.RelativeLocation = FVector(165.0, 0.0, 42.5);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftFoot")
	USceneComponent LeftJetLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightFoot")
	USceneComponent RightJetLocation;

	UPROPERTY(DefaultComponent)
	UTrajectoryTraversalComponent TraversalComp;
	default TraversalComp.Methods.Add(UIslandJumpUpTraversalMethod);
	default TraversalComp.Methods.Add(UIslandJumpDownTraversalMethod);

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueImpactResponseComponent DamageResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldComponent ForceFieldComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
#if EDITOR
	default RequestCapabilityComp.InitialStoppedPlayerCapabilities.Add(n"IslandPunchotronSidescrollerDevTogglesCapability");
#endif

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UIslandPunchotronSidescrollerLandingComponent LandingComp;

	TArray<AIslandSidescrollerOneWayPlatform> NearbyOneWayPlatforms;

	UIslandPunchotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ApplyDefaultSettings(IslandPunchotronSidescrollerHealthBarSettings);
		Settings = UIslandPunchotronSettings::GetSettings(this);
		ForceFieldComp.AutoRespawnCooldown = Settings.SidescrollerForceFieldDepletedCooldown;
		UHazeTeam PunchotronTeam = JoinTeam(IslandPunchotronSidescrollerTags::IslandPunchotronSidescrollerTeamTag);

		for (AIslandSidescrollerOneWayPlatform Platform : TListedActors<AIslandSidescrollerOneWayPlatform>())
		{
			if (Math::Abs(ActorLocation.X - Platform.ActorLocation.X) < 1000)
				NearbyOneWayPlatforms.Add(Platform);
		}
#if EDITOR
		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::Mio, this);		
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(IslandPunchotronSidescrollerTags::IslandPunchotronSidescrollerTeamTag);
	}

	void AddMovementIgnoreOneWayPlatforms(FInstigator Instigator)
	{
		for (AIslandSidescrollerOneWayPlatform Platform : NearbyOneWayPlatforms)
		{
			MoveComp.AddMovementIgnoresActor(Instigator, Platform);
		}
	}

	void ClearMovementIgnoreOneWayPlatforms(FInstigator Instigator)
	{
		MoveComp.RemoveMovementIgnoresActor(Instigator);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ForceFieldComp.AutoRespawnCooldown = UIslandPunchotronSettings::GetSettings(this).SidescrollerForceFieldDepletedCooldown;
	}

	bool bIsHaywireDisabled = false;
	bool bIsCobraStrikeDisabled = false;
	bool bIsKickDisabled = false;
	bool bIsJumpDisabled = false;

#endif
}

namespace IslandPunchotronSidescrollerTags
{
	const FName IslandPunchotronSidescrollerTeamTag = n"IslandPunchotronSidescrollerTeam";
}

asset IslandPunchotronSidescrollerHealthBarSettings of UBasicAIHealthBarSettings
{
	HealthBarOffset = FVector(0.0, 0.0, 280.0);
}
