asset SimonSaysMonkeyKingSheet of UHazeCapabilitySheet
{
	AddCapability(n"Tundra_SimonSaysMonkeyKingIdleCapability");
	AddCapability(n"Tundra_SimonSaysMonkeyKingDanceJumpCapability");
}

UCLASS(Abstract)
class ATundra_SimonSaysMonkeyKing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;
	default MeshComp.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPose;
	// OLIVERL TODO: REMOVE ALWAYS TICK POSE WHEN PROPER ANIMATIONS WORK!

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SimonSaysMonkeyKingSheet);

	UPROPERTY(DefaultComponent)
	UTundra_SimonSaysMonkeyKingMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedActorPos;

	ATundra_SimonSaysManager Manager;
	FRotator OriginalRotation;
	USceneComponent CurrentTargetPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Manager = TundraSimonSays::GetManager();
		Manager.MonkeyKing = this;
		Manager.AnimComps.Add(this, UTundra_SimonSaysAnimDataComponent::GetOrCreate(this));
		OriginalRotation = ActorRotation;
		AddActorDisable(Manager);
	}
}