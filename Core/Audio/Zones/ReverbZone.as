
UCLASS(Meta = (NoSourceLin), HideCategories = "Collision Rendering Cooking Debug")
class AReverbZone : AHazeAudioZone
{
	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);
	default ZoneType = EHazeAudioZoneType::Reverb;
	default BrushComponent.SetCollisionProfileName(n"AudioZone");	

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "ZoneReverb";
	default EditorIcon.RelativeScale3D = FVector(2);
#endif

	UPROPERTY(EditInstanceOnly, Category="Audio")
	float SendLevelOverride = 1;

	UPROPERTY(EditInstanceOnly, Category="Audio")
	UHazeAudioAuxBus ReverbBusOverride = nullptr;

	// In dB
	UPROPERTY(EditInstanceOnly, Category="Audio")
	float PlayerVoGameAuxSendVolume = 0;

	// In dB
	UPROPERTY(EditInstanceOnly, Category="Audio")
	float PlayerVoUserAuxSendVolume0 = 0;

	// By default we will apply it on \Actor-Mixer Hierarchy\Default Work Unit\Amix_Master\VO\Amix_VO
	UPROPERTY(EditInstanceOnly, Category="Audio")
	UHazeAudioActorMixer VoAmixForGameAuxSendVolumeOverride = nullptr;

	private bool bActivatingZone = false;

	UFUNCTION(BlueprintOverride)
	float GetSendLevel()
	{
		if (!Math::IsNearlyEqual(SendLevelOverride, 1))
			return SendLevelOverride;

		if (ZoneAsset != nullptr)
			return ZoneAsset.SendLevel;

		return 1;
	}

	UFUNCTION(BlueprintOverride)
	UHazeAudioAuxBus GetReverbBus()
	{
		if (ReverbBusOverride != nullptr)
			return ReverbBusOverride;

		if (ZoneAsset != nullptr)
			return ZoneAsset.ReverbBus;

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		AudioZone::OnBeginPlay(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveZoneRtpcToTarget(ZoneFadeTargetValue, DeltaSeconds);
		if (!bShouldTick && ZoneRTPCValue == ZoneFadeTargetValue)
		{
			SetZoneTickEnabled(false);
		}
	}
}