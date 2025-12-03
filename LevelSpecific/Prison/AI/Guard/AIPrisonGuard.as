UCLASS(Abstract)
class AAIPrisonGuard : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardMagneticBurstDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GroundPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonGuardMovementCapability"); 

	default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::PlayerAbilityZoe, ECollisionResponse::ECR_Block);
	default CapsuleComponent.CapsuleRadius = 40.0;
	default CapsuleComponent.CapsuleHalfHeight = 140.0;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
    default MoveToComp.DefaultSettings = BasicAICharacterGroundPathfollowingSettings;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	USceneComponent RightZapper;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftHand")
	USceneComponent LeftZapper;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent)
	UPrisonGuardComponent GuardComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UPrisonGuardAnimationComponent GuardAnimComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedPrisonGuardMovementComponent CrumbGuardMovementComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> PlayerDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> PlayerDeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		UPlayerRespawnComponent PlayerRespawnComp = UPlayerRespawnComponent::Get(Game::Zoe);
		PlayerRespawnComp.OnPlayerRespawned.AddUFunction(this, n"PlayerRespawned");

		SetActorControlSide(Game::Zoe);
		TargetingComponent.Target = Game::Zoe;

		RespawnComp.OnPostRespawn.AddUFunction(this, n"Respawned");
	}

	UFUNCTION()
	private void Respawned()
	{
		TargetingComponent.Target = Game::Zoe;
		UPrisonGuardEffectHandler::Trigger_OnRespawn(this);
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		TargetingComponent.Target = RespawnedPlayer;
	}
}

