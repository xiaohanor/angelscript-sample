UCLASS(Abstract)
class USoftSplit_SpotTracking_SoundDef_Base : USpot_Tracking_SoundDef
{
	private TArray<USoftSplitAudioSpotSoundComponent> SpotComps;

	UFUNCTION(BlueprintOverride)
	void ParentSetup() override
	{
		Super::ParentSetup();

		HazeOwner.GetComponentsByClass(USoftSplitAudioSpotSoundComponent, SpotComps);
	
		if (SpotComps.Num() > 0)
		{
			for(auto Spot : SpotComps)
			{
				for (auto AudioComponent: AudioComponents)
				{
					if (AudioComponent.GetAttachParent() == Spot)
					{
						Spot.SetSoundDefAudioComponent(AudioComponent);
						break;
					}
				}
			}
		}
	}
}