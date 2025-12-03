
// A Spot sound actor to interface with the Prefab system.
class APrefabSpotSound : AHazeActor
{
	UPROPERTY(EditAnywhere)
	FHazeSpotSoundAssetData AssetData;

	UPROPERTY(EditAnywhere)
	float AttenuationScale = 5000;
	
	UPROPERTY(EditAnywhere)
	TMap<UHazeAudioRtpc, float> DefaultRtpcs;

	UPROPERTY(EditAnywhere)
	TArray<FHazeAudioNodePropertyParam> NodeProperties;

	UPROPERTY(EditAnywhere)
	bool bLinkedToZone = false;

	UPROPERTY(EditAnywhere)
	bool bFollowRelevance = false;

	UPROPERTY(DefaultComponent, NotEditable)
	USpotSoundComponent SpotSoundComponent;

	void ApplyOnComponent()
	{
		SpotSoundComponent.AssetData.SetSoundAssetData(AssetData.GetAsset());
		SpotSoundComponent.Settings.AttenuationScale = AttenuationScale;
		SpotSoundComponent.Settings.DefaultRtpcs = DefaultRtpcs;
		SpotSoundComponent.Settings.NodeProperties = NodeProperties;
		SpotSoundComponent.bLinkToZone = bLinkedToZone;
		SpotSoundComponent.bLinkedZoneFollowRelevance = bFollowRelevance;
	}
}