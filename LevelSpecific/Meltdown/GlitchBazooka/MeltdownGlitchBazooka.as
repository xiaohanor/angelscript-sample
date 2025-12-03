UCLASS(Abstract)
class AMeltdownGlitchBazooka : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Bazooka;

	UPROPERTY(DefaultComponent, Attach = Bazooka)
	USceneComponent MuzzleLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorVisualsBlock(this);
	}

	void Appear()
	{
		RemoveActorVisualsBlock(this);
	}

	void Disappear()
	{
		AddActorVisualsBlock(this);
	}
};