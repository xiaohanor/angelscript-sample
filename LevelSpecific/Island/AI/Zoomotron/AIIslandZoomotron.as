UCLASS(Abstract)
class AAIIslandZoomotron : ABasicAIFlyingCharacter
{
	// Do not use pathfinding, just move straight to destination
	default MoveToComp.DefaultSettings = BasicAIFlyingIgnorePathfindingMoveToSettings;

	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;
	default CapsuleComponent.CapsuleHalfHeight = 40.0;
	default CapsuleComponent.CapsuleRadius = 40.0;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandZoomotronBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ProjectileResponseComp;
	
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

    UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
    UStaticMeshComponent MeshBody;

	UPROPERTY(DefaultComponent, Attach = "MeshBody")
    UStaticMeshComponent MeshSpikes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		//OnPostReset();
		//RespawnComp.OnPostReset.AddUFunction(this, n"OnPostReset");
	}

	// TODO: check transition sync time out
	// UFUNCTION()
	// private void OnPostReset()
	// {
	// 	// Set control side, pick closest Player
	// 	if (HasControl())
	// 	{
	// 		if (Game::Mio.ActorLocation.DistSquared(ActorLocation) < Game::Zoe.ActorLocation.DistSquared(ActorLocation))
	// 			CrumbSetActorControlSide(Game::Mio);
	// 		else
	// 			CrumbSetActorControlSide(Game::Zoe);
	// 	}
				
	// }

	// UFUNCTION(CrumbFunction)
	// void CrumbSetActorControlSide(AHazePlayerCharacter Player)
	// {
	// 	SetActorControlSide(Player);
	// 	Debug::DrawDebugSphere(ActorLocation, LineColor = Player.GetPlayerDebugColor(), Duration = 5.0);
	// 	Debug::DrawDebugLine(ActorLocation, Player.ActorLocation, LineColor = Player.GetPlayerDebugColor(), Duration = 5.0);
	// }
}