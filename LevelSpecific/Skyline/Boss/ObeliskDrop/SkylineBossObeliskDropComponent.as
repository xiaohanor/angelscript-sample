class USkylineBossObeliskDropComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBossObeliskDrop> ObeliskDropClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};