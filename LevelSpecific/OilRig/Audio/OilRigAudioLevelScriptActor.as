class AOilRigAudioLevelScriptActor : AAudioLevelScriptActor
{
	UFUNCTION(BlueprintCallable)
	void OverrideAmbientBattleRelevanceTracking(USpotSoundComponent AmbientBattleSpotSoundComp, bool bFollowRelevance = true)
	{
		if(AmbientBattleSpotSoundComp == nullptr)
			return;

		AmbientBattleSpotSoundComp.UpdateZoneOcclusionTracking(nullptr, nullptr, bFollowRelevance, true);
	}
}