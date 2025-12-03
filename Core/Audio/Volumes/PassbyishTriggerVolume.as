UCLASS(HideCategories = "Rendering Physics Collision Debug Actor Cooking")
class APassbyishTriggerVolume : APlayerAudioVolumeBase
{
#if EDITOR
	UPROPERTY(NotVisible, DefaultComponent)
	UPassbyishTriggerEditorComponent PassbyishEditorComponent;

	UPROPERTY(VisibleInstanceOnly)
	FTransform SoundPosition;
#endif

	UPROPERTY(VisibleInstanceOnly)
	FTransform PassbyTransform;

	void SetupEmitter() override
	{
		FHazeAudioPoolComponentParams PoolingParams;
		PoolingParams.bReverbEnabled = true;

		UHazeAudioComponent AudioComp = Audio::GetPooledAudioComponent(PoolingParams);

		PassbyTransform = FTransform(
			PassbyTransform.Rotation,
			GetActorTransform().TransformPosition(PassbyTransform.Location),
			PassbyTransform.Scale3D);

		AudioComp.SetWorldTransform(PassbyTransform);
		VolumeEmitter = AudioComp.GetEmitter(this);		

		VolumeEmitter.SetAttenuationScaling(AttenuationScaling);
	}

	void PlayOnEnter(AHazePlayerCharacter Player) override
	{
		//Debug::DrawDebugLine(Player.GetActorLocation(), PassbyTransform.Location, FLinearColor::Red, Thickness = 6.0, Duration = 10.0);
		//Debug::DrawDebugPoint(PassbyTransform.Location, 30.0, FLinearColor::DPink, 10.0);
		//PrintToScreenScaled("PlayPassby", 1);

		if(Event != nullptr)		
		{					
			VolumeEmitter.PostEvent(Event, PostType = EHazeAudioEventPostType::Passby);
		}
		else if(SoundDefRef.SoundDef != nullptr)
		{
			SoundDefRef.SpawnSoundDefOneshot(this, PassbyTransform, nullptr, bCanTick);
		}
	}
}

class UPassbyTriggerVolumeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = APassbyishTriggerVolume;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideProperty(n"PassbyTransform");
		HideProperty(n"SoundPosition");		
	}

}