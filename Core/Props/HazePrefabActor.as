// Base class for all environment geometry BPs.
// TODO: Rename to avoid confusion with APrefabRoot
UCLASS(Abstract)
class AHazePrefabActor : AHazeActor
{
	UPROPERTY(EditAnywhere)
	bool bAffectsNavigation = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UStaticMeshComponent> StaticMeshes;
		GetComponentsByClass(StaticMeshes);
		for (UStaticMeshComponent Mesh : StaticMeshes)
		{
			Mesh.bCanEverAffectNavigation = bAffectsNavigation;
		}
	}
}
