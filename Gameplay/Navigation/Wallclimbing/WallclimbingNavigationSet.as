class UWallclimbingNavigationVolumeSet : UClass
{
	TArray<AVolume> Volumes;
	
	void Register(AVolume Volume)
	{
		Volumes.AddUnique(Volume);
	}
	
	void Unregister(AVolume Volume)
	{
		Volumes.RemoveSingle(Volume);
	}
}
