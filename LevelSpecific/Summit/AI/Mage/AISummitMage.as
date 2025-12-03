namespace SummitMageTags
{
	const FName SummitMageCritterTeam = n"SummitMageCritterTeam";
}

UCLASS(Abstract, meta = (DefaultActorLabel = "Mage"))
class AAISummitMage : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitMageCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFindTraversalAreaCapability");

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	default TailAttackResponseComp.ImpactType = ETailAttackImpactType::Enemy;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UPROPERTY(DefaultComponent)
	UTeleportTraversalComponent TraversalComp;
	default TraversalComp.Method = USummitTeleportTraversalMethod;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent DarkMagicSystem;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UStaticMeshComponent Shard;
	default Shard.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Shard.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default Shard.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UAISummitTEMPEnemyMeshComponent TEMPSummitMeshComp;
	default TEMPSummitMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(Category = "Setup")
	TSubclassOf<ASummitMageSpiritBall> SpiritBallClass;

	UPROPERTY(Category = "Setup")
	TSubclassOf<AAISummitTotem> TotemClass;
	AAISummitTotem Totem;

	UPROPERTY(Category = "Setup")
	TSubclassOf<ASummitMageGroundBeam> SummitMageGroundBeamClass;

	UPROPERTY(Category = "Setup")
	TSubclassOf<AHazeActor> TeleportIndicatorClass;
	AHazeActor TeleportIndicator;

	UPROPERTY(DefaultComponent)
	USummitCameraShakeComponent CameraShakeComp;

	UPROPERTY(DefaultComponent)
	UBasicAIKnockdownComponent KnockdownComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	// default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet); Don't need to use fitness for TopDown enemy
	default RequestCapabilityComp.PlayerSheets.Add(PlayerTraversalSheet);
	
	UPROPERTY(DefaultComponent)
	USummitMageSpiritBallLauncherComponent SpiritBallLauncherComp;

	UPROPERTY(DefaultComponent)
	USummitMageCritterSlugLauncherComponent CritterSlugLauncherComp;

	UPROPERTY(DefaultComponent)
	USummitMageDonutComponent DonutComp;

	UPROPERTY(DefaultComponent)
	USummitMageModeComponent ModeComp;

	UPROPERTY()
	USummitMageSettings DefaultMageSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		CapsuleComponent.QueueComponentForUpdateOverlaps();

		// AcidTailBreakComp.OnBrokenByTail.AddUFunction(this, n"OnBrokenByTail");
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnTailDragonRollImpact");

		// Visual indicator only, does not need networking
		TeleportIndicator = SpawnActor(TeleportIndicatorClass);
		HideTeleportIndicator();

		if(DefaultMageSettings != nullptr)
			ApplySettings(DefaultMageSettings, this);
	}

	UFUNCTION()
	void ShowTeleportIndicator(FVector WorldLocation)
	{
		TeleportIndicator.SetActorLocation(WorldLocation);
		TeleportIndicator.RemoveActorVisualsBlock(this);
	}

	UFUNCTION()
	void HideTeleportIndicator()
	{
		TeleportIndicator.AddActorVisualsBlock(this);
	}


	UFUNCTION()
	private void OnTailDragonRollImpact(FRollParams Params)
	{
		KnockdownComp.Knockdown(EBasicAIKnockdownType::Default, FVector(0.0));
		MovementComponent.AddPendingImpulse(Params.RollDirection * 100.0);
		HealthComp.TakeDamage(1000, EDamageType::MeleeBlunt, Params.PlayerInstigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Multiplier = Math::Sin(Time::GameTimeSeconds * 2.0);
		FVector BobbingLoc = FVector(0.0, 0.0, 15.0 * Multiplier);
		MeshOffsetComponent.RelativeLocation = BobbingLoc;
	}

	void SpawnTotem()
	{
		if (Totem != nullptr)
			return;

		FVector SpawnLoc = ActorLocation + (ActorForwardVector * 150.0); 
		Totem = SpawnActor(TotemClass, SpawnLoc, ActorRotation);
	}
}

namespace SummitMageTags
{
	const FName SpiritBallToken = n"SpiritBallToken";
}