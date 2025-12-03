/**
 * Component type to place inside blueprint actors that need to use HazeProp functionality in their materials.
 */
class UHazePropStaticMeshComponent : UStaticMeshComponent
{
#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		UpdatePrimitiveData();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		UpdatePrimitiveData();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentCompiledInBlueprint()
	{
		UpdatePrimitiveData();
	}

	float Hash12(int x, int y)
	{
		int Q1 = 1103515245 * ((x >> 1) ^ y);
		int Q2 = 1103515245 * ((y >> 1) ^ x);
		int N = 1103515245 * (Q1 ^ (Q2 >> 3));
		return Math::Frac(float(N) * (1.0 / float(0xffffffff)));
	}

	void UpdatePrimitiveData()
	{
		// Random value based on world position.
		FVector ComponentLocation = GetWorldLocation();
		float RandomValue = Hash12(int(ComponentLocation.X), int(ComponentLocation.Y) + int(ComponentLocation.Z));
		SetDefaultCustomPrimitiveDataFloat(0, RandomValue);

		// General object scale used for tilers.
		float GeneralScale = GetWorldScale().DotProduct(FVector::OneVector);
		GeneralScale = Math::Abs(GeneralScale) / 3.0;
		SetDefaultCustomPrimitiveDataFloat(1, GeneralScale);
	}
#endif
}