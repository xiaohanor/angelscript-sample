
struct FWeaponFlybyVariableSettings
{
	UPROPERTY()
	UHazeAudioEvent Event;
	
	UPROPERTY()
	float VoiceVolume;

	UPROPERTY()
	float VoiceVolumeNormalizedDistanceMax;
	UPROPERTY()
	float VoiceVolumeNormalizedDistanceMin;

	// MAKE UP GAIN
	UPROPERTY()
	float MakeupGain;

	UPROPERTY()
	float MakeupGainRandomMin;
	UPROPERTY()
	float MakeupGainRandomMax;

	UPROPERTY()
	float MakeupGainNormalizedDistanceMax;
	UPROPERTY()
	float MakeupGainNormalizedDistanceMin;

	// PITCH
	UPROPERTY()
	float Pitch;

	UPROPERTY()
	float PitchRandomMin;
	UPROPERTY()
	float PitchRandomMax;

	UPROPERTY()
	float PitchNormalizedDistanceMax;
	UPROPERTY()
	float PitchNormalizedDistanceMin;
}

UCLASS(Abstract)
class UGameplay_Weapon_Projectile_Flybys_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UBasicAIProjectileComponent AIProjectileComponent;

	UPROPERTY(BlueprintReadOnly)
	bool bIsPlayerProjectile = false;

	UPROPERTY()
	UHazeAudioRtpc Rtpc_Projectile_Shared_Flybys_VoiceVolume;
	UPROPERTY()
	UHazeAudioRtpc Rtpc_Projectile_Shared_Flybys_MakeUpGain;
	UPROPERTY()
	UHazeAudioRtpc Rtpc_Projectile_Shared_Flybys_Pitch;
	UPROPERTY()
	UHazeAudioRtpc Rtpc_Projectile_Shared_Flybys_ReverbSendVolume;

	FWeaponFlybyVariableSettings Settings;
	float NormalizedObserverDistance;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AIProjectileComponent = UBasicAIProjectileComponent::Get(HazeOwner);
		bIsPlayerProjectile = (AIProjectileComponent == nullptr);
		OnPollSettingsFromBP(Settings);
	}

	UFUNCTION(BlueprintEvent)
	void OnPollSettingsFromBP(FWeaponFlybyVariableSettings&out OutSettings){}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bIsPlayerProjectile && AIProjectileComponent.bIsExpired)
			return true;

		return false;
	}

	UFUNCTION()
	void OnFlybyTrigger(float InNormalizedObserverDistance)
	{
		NormalizedObserverDistance = InNormalizedObserverDistance;

		SetVoiceVolume();
		SetMakeupGain();
		SetPitch();
		SetReverbSend();
	}

	void SetVoiceVolume()
	{
		auto VoiceVolumeResult = Settings.VoiceVolume *
			Math::GetMappedRangeValueClamped
			(
				FVector2D(0,1),
				FVector2D(Settings.VoiceVolumeNormalizedDistanceMax, Settings.VoiceVolumeNormalizedDistanceMin),
				NormalizedObserverDistance
			);

		DefaultEmitter.SetRTPC(Rtpc_Projectile_Shared_Flybys_VoiceVolume, VoiceVolumeResult, 0);
	}

	void SetMakeupGain()
	{
		auto MakeUpGainResult = Settings.MakeupGain *
			Math::RandRange(Settings.MakeupGainRandomMin, Settings.MakeupGainRandomMax) *
			Math::GetMappedRangeValueClamped
			(
				FVector2D(0,1),
				FVector2D(Settings.MakeupGainNormalizedDistanceMax, Settings.MakeupGainNormalizedDistanceMin),
				NormalizedObserverDistance
			);

		DefaultEmitter.SetRTPC(Rtpc_Projectile_Shared_Flybys_MakeUpGain, MakeUpGainResult, 0);
	}

	void SetPitch()
	{
		auto PitchResult = Settings.Pitch *
			Math::RandRange(Settings.PitchRandomMin, Settings.PitchRandomMax) *
			Math::GetMappedRangeValueClamped
			(
				FVector2D(0,1),
				FVector2D(Settings.PitchNormalizedDistanceMax, Settings.PitchNormalizedDistanceMin),
				NormalizedObserverDistance
			);

		DefaultEmitter.SetRTPC(Rtpc_Projectile_Shared_Flybys_Pitch, PitchResult, 0);
	}

	void SetReverbSend()
	{
		auto Environment = GetPrioritizedEnvironmentType(DefaultEmitter);
		float ReverbSend = 0.5;
		switch(Environment)
		{
			case EHazeAudioEnvironmentType::Swtc_Environment_Interior_Small:
			case EHazeAudioEnvironmentType::Swtc_Environment_Interior_Large:
			case EHazeAudioEnvironmentType::Swtc_Environment_Interior_XLarge:
			case EHazeAudioEnvironmentType::Swtc_Environment_Tunnel_Small:
			case EHazeAudioEnvironmentType::Swtc_Environment_Tunnel_Large:
			ReverbSend = 1.5;
			break;
			// Same as default.
			case EHazeAudioEnvironmentType::Swtc_Environment_Exterior_Field:
			case EHazeAudioEnvironmentType::Swtc_Environment_Exterior_Forest:
			case EHazeAudioEnvironmentType::Swtc_Environment_Exterior_Canyon:
			case EHazeAudioEnvironmentType::Swtc_Environment_Exterior_Urban:
			default:
			break;
		}

		DefaultEmitter.SetRTPC(Rtpc_Projectile_Shared_Flybys_ReverbSendVolume, ReverbSend, 0);
	}

}