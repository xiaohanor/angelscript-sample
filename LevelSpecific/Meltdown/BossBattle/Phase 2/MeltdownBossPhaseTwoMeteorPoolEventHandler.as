UCLASS(Abstract)
class UMeltdownBossPhaseTwoMeteorPoolEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatImpact(FMeltdownBossPhaseTwoMeteorPoolEventHandlerData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundImpact(FMeltdownBossPhaseTwoMeteorPoolEventHandlerData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AsteroidDestroyed(FMeltdownBossPhaseTwoMeteorPoolEventHandlerData Data)
	{
	}

};

struct FMeltdownBossPhaseTwoMeteorPoolEventHandlerData
{	
	UPROPERTY()
	UStaticMeshComponent AsteroidMesh;

	 FMeltdownBossPhaseTwoMeteorPoolEventHandlerData (UStaticMeshComponent _AsteroidMesh)
	{
		AsteroidMesh = _AsteroidMesh;
	}
	
}