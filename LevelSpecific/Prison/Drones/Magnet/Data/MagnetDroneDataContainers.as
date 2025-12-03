struct FDroneMagnetTraceForMagneticSurfaceResult
{
	UDroneMagneticSurfaceComponent MagneticSurfaceComponent;
	FVector ImpactPoint;
	FVector ImpactNormal;

	// Since operator overloading is not supported for C++ execution, I made this function.
	int FindInArray(const TArray<FDroneMagnetTraceForMagneticSurfaceResult>& Array)
	{
		for(int i = 0; i < Array.Num(); i++)
		{
			if(Array[i].MagneticSurfaceComponent == MagneticSurfaceComponent)
				return i;
		}

		return -1;
	}
}
