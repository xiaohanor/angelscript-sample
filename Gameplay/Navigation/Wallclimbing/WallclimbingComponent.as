class UWallclimbingComponent : UActorComponent
{
	UPROPERTY()
	FVector PreferredGravity = FVector::UpVector;

	TInstigated<FVector> DestinationUpVector;
	default DestinationUpVector.SetDefaultValue(FVector::ZeroVector) ; // Unbiased destination

	AWallclimbingNavigationVolume Navigation;

	TArray<FWallClimbingPathNode> Path;
	bool bDebug = false;

	void Reset()
	{
		Path.Empty();
	}
}
