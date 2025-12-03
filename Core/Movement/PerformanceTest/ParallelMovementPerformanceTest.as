#if TEST
UCLASS(NotBlueprintable)
class AParallelMovementPerformanceTest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"ParallelMovementPerformanceTestCapability");

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Debug::DrawDebugCapsule(ActorLocation, CapsuleComp.CapsuleHalfHeight, CapsuleComp.CapsuleRadius, ActorRotation);
	}
};
#endif