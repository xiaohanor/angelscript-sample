class ALightningAttackpoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10));
#endif	

	private TArray<ULightningSubPoint> SubPoints;

	UPROPERTY()
	bool bTelegraphActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(SubPoints);
	}

	TArray<ULightningSubPoint> GetAllSubPoints()
	{
		return SubPoints;
	}

	UFUNCTION(BlueprintEvent)
	void ActivateLightningTelegraph() {}
	UFUNCTION(BlueprintEvent)
	void DeactivateLightningTelegraph() {}
}

class ULightningSubPoint : USceneComponent
{

}