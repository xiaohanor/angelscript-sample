UCLASS(Abstract)
class ASandSharkHazard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SharkRoot;

	UPROPERTY(DefaultComponent, Attach = SharkRoot)
	UHazeCharacterSkeletalMeshComponent SharkMesh;
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	float TimeWhenSpawned = 0;

	float GetTimeAlive() const property
	{
		return Time::GetGameTimeSince(TimeWhenSpawned);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeWhenSpawned = Time::GetGameTimeSeconds();
	}
};