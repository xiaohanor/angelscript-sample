struct FInverseDeatchVolumeSet
{
	TSet<AInverseDeathVolume> Set;
}

UCLASS(NotBlueprintable, NotPlaceable)
class UInverseDeathVolumeManager : UActorComponent
{
	TPerPlayer<FInverseDeatchVolumeSet> InverseDeathVolumes;
};