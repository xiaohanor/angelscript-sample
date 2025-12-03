UCLASS(Abstract)
class AIslandFallingPlatformsForceField : AIslandRedBlueForceField
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		SetForceFieldActive(false);
		TListedActors<AIslandFallingPlatformsManager> ListedManager;
		ListedManager.Single.ForceFields.AddUnique(this);
	}
}