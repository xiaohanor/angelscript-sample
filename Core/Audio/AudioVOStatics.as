
namespace VO
{
	const FHazeAudioID Rtpc_VO_Player_Zoe_Gaia_Voice_Metering = FHazeAudioID("Rtpc_VO_Player_Zoe_Gaia_Voice_Metering");

	float GetZoeGaiaVoiceVolume()
	{
		float32 ZoesVoiceVolumePeak = 0;
		float ZoesVoiceVolumeNormalized = 0;

		if (AudioComponent::GetGlobalRTPC(Rtpc_VO_Player_Zoe_Gaia_Voice_Metering, ZoesVoiceVolumePeak))
		{
			// Just a approximation.
			ZoesVoiceVolumeNormalized = Math::GetPercentageBetweenClamped(-72, -12, ZoesVoiceVolumePeak);
		}

#if TEST
		PrintToScreen(f"ZoesVoiceVolume: Volume: {ZoesVoiceVolumePeak} - Normalized {ZoesVoiceVolumeNormalized}");
#endif

		return ZoesVoiceVolumeNormalized;
	}

	const FHazeAudioID Rtpc_VO_IslandPA_Voice_Metering = FHazeAudioID("Rtpc_VO_IslandPA_Voice_Metering");

	float GetIslandPAVoiceVolume()
	{
		float32 VolumePeak = 0;
		float VolumePeakNormalized = 0;

		if (AudioComponent::GetGlobalRTPC(Rtpc_VO_IslandPA_Voice_Metering, VolumePeak))
		{
			// Just a approximation.
			VolumePeakNormalized = Math::GetPercentageBetweenClamped(-72, -12, VolumePeak);
		}

#if TEST
		PrintToScreen(f"IslandPA Volume: {VolumePeak} - Normalized {VolumePeakNormalized}");
#endif

		return VolumePeakNormalized;
	}
}