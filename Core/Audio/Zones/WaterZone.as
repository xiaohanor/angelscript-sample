UCLASS(Meta = (NoSourceLin), HideCategories = "Collision Rendering Cooking Debug")
class AWaterZone : AAmbientZone
{
	default ZoneType = EHazeAudioZoneType::Water;

#if EDITOR
	UPROPERTY(VisibleAnywhere)
	TArray<TSoftObjectPtr<AHazePostProcessVolume>> ConnectedSwimmingVolumes;
#endif
}
