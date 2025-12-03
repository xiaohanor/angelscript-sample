enum ERemoteHackingType
{
	Drone,
	ExoSuit
}

UCLASS(Abstract)
class UGameplay_Ability_Player_Hacking_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaunchStarted(FRemoteHackingStartParams HackingParams){}

	UFUNCTION(BlueprintEvent)
	void OnHackingStopped(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ERemoteHackingType HackingType = ERemoteHackingType::Drone;

	UPROPERTY(BlueprintReadOnly)
	UVODamageDeathSettings DamageDeathSettingsForVO;

	// Time at which hacking sounds reach their apex after traveling towards hacking target
	// i.e, the time it takes for hacking player to reach the target at the furthest possible range of activation
	// Not used if hacking as drone	
	const float REMOTE_HACKING_APEX_TIME_MS = 1000.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{		
		if(UPlayerSwarmDroneComponent::Get(PlayerOwner) == nullptr)
			HackingType = ERemoteHackingType::ExoSuit;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (PlayerOwner != nullptr)
			PlayerOwner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintCallable)
	void GetHackingSeekData(const float InTimeToTarget, FHazeAudioSeekData&out SeekData, float&out DelayTime)
	{
		SeekData = FHazeAudioSeekData();
		SeekData.SeekType = EHazeAudioSeekType::Time;
		DelayTime = 0.0;

		if(HackingType == ERemoteHackingType::Drone)
		{
			SeekData.SeekPosition = 0.1;
			SeekData.MarkerConfig = EHazeAudioSeekMarkerConfig::Next;
		}
		else
		{
			const float WantedSeekPosition = REMOTE_HACKING_APEX_TIME_MS - (InTimeToTarget * 1000);

			if(WantedSeekPosition < 0)
			{
				DelayTime = Math::Abs(WantedSeekPosition / 1000.0);
			}
			else
			{
				SeekData.SeekPosition = WantedSeekPosition;
			}
		}
	}

}