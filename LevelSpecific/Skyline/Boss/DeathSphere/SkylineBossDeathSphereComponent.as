class USkylineBossDeathSphereComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBossDeathSphere> DeathSphereClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};