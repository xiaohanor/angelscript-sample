UCLASS(Abstract)
class APrisonCourtyardShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHackableSniperTurretResponseComponent ResponseComp;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHackableSniperTurretHit.AddUFunction(this,n"SniperHit");
	}

	UFUNCTION()
	private void SniperHit(FHackableSniperTurretHitEventData EventData)
	{
	}
};
