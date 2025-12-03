class AAlienCruiserMissileTarget : AHazeActor
{
	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UDecalComponent TargetDecal;
	default TargetDecal.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	AAlienCruiser Cruiser;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	int opCmp(AAlienCruiserMissileTarget Other) const
	{
		float DistSqrdToCruiser = ActorLocation.DistSquared(Cruiser.ActorLocation);
		float OtherDistSqrdToCruiser = Other.ActorLocation.DistSquared(Cruiser.ActorLocation);
		if(DistSqrdToCruiser < OtherDistSqrdToCruiser)
			return 1;
		else if(DistSqrdToCruiser > OtherDistSqrdToCruiser)
			return -1;
		else 
			return 0;
	}
};