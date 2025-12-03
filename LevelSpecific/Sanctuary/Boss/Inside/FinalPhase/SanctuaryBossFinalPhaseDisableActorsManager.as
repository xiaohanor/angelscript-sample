class ASanctuaryBossFinalPhaseDisableActorsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> CollisionActors;

	UPROPERTY(EditInstanceOnly)
	TArray<ADeathVolume> DeathVolumeActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto CollisionActor : CollisionActors)
		{
			CollisionActor.SetActorEnableCollision(false);
		}
		for (auto DeathVolumeActor : DeathVolumeActors)
		{
			DeathVolumeActor.DisableDeathVolume(this);
		}
	}

	UFUNCTION()
	void EnableActors()
	{
		for (auto CollisionActor : CollisionActors)
		{
			CollisionActor.SetActorEnableCollision(true);
		}
		for (auto DeathVolumeActor : DeathVolumeActors)
		{
			DeathVolumeActor.EnableDeathVolume(this);
		}
	}
};