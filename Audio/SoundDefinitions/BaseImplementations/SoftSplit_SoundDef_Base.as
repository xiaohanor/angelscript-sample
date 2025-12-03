UCLASS(Abstract)
class USoftSplit_SoundDef_Base : USoundDefBase
{
	private TArray<USoftSplitAudioSpotSoundComponent> SpotComps;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
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