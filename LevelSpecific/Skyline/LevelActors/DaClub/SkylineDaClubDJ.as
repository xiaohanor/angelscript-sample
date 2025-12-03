class ASkylineDaClubDJ : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector ToClosestPlayer = (Game::GetClosestPlayer(ActorLocation).ActorLocation - ActorLocation);
		auto Rotation = FQuat::Slerp(SkelMesh.ComponentQuat, ToClosestPlayer.VectorPlaneProject(ActorUpVector).ToOrientationQuat(), 2.0 * DeltaSeconds);
		SkelMesh.ComponentQuat = Rotation;
	}
};