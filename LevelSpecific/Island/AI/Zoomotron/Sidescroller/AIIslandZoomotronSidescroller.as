UCLASS(Abstract)
class AAIIslandZoomotronSidescroller : ABasicAICharacter
{
	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;
	default CapsuleComponent.CapsuleHalfHeight = 40.0;
	default CapsuleComponent.CapsuleRadius = 40.0;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandZoomotronSidescrollerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandSidescrollerFlyingMovementCapability");
	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ProjectileResponseComp;
	
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);	

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueTargetableComponent TargetableComp;

	// From ABasicAIFlyingCharacter
	UPROPERTY(DefaultComponent)
	UBasicAIFlightComponent FlightComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		RespawnComp.OnRespawn.AddUFunction(FlightComp, n"Reset");
	}
}