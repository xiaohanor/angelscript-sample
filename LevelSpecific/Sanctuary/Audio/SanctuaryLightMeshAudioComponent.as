UCLASS(Abstract)
class USanctuaryLightMeshAudioComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TPerPlayer<bool> TrackPlayer;
	default TrackPlayer[0] = true;
	default TrackPlayer[1] = true;

	UFUNCTION(BlueprintEvent)
	void GetLightMeshAudioPositions(TArray<FAkSoundPosition>& outPositions) {}
}