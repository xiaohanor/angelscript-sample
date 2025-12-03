
UCLASS(Abstract)
class USideContent_Skyline_DaClub_BoomBox_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ChannelThree(){}

	UFUNCTION(BlueprintEvent)
	void ChannelTwo(){}

	UFUNCTION(BlueprintEvent)
	void ChannelOne(){}

	UFUNCTION(BlueprintEvent)
	void Static(){}

	UFUNCTION(BlueprintEvent)
	void ChannelFour(){}

	/* END OF AUTO-GENERATED CODE */
	ASkylineDaClubBoombox BoomBox;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEffectShareSet FilterFX;
	private FHazeAudioRuntimeEffectInstance FilterFXInstance;
	private float FXCrossfadeDuration = 1.0;	
	private float FXFadeAlpha = 1.0;

	private const FHazeAudioID MioFilterRTPC ("Rtpc_HazeFiltering_Mio");
	private const FHazeAudioID ZoeFilterRTPC ("Rtpc_HazeFiltering_Zoe");
	private FHazeAudioID FilterRTPC;

	UFUNCTION(BlueprintOverride)
    void ParentSetup()
    {
        BoomBox = Cast<ASkylineDaClubBoombox>(HazeOwner);
	}	

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get BoomBox Channel Alphas"))
    float GetBoomBoxChannelAlphas() {
        float CurrentSpin = Math::Abs(BoomBox.Dial.RelativeRotation.Yaw);
        if (BoomBox.Dial.RelativeRotation.Yaw < 0)
            CurrentSpin = 180 + (180 + BoomBox.Dial.RelativeRotation.Yaw);
        float NormalizedSpin = Math::GetMappedRangeValueClamped(FVector2D(0,360),FVector2D(0,1),CurrentSpin);
        return NormalizedSpin;
    }

	UFUNCTION(BlueprintCallable)
	void StartFilterFX()
	{
		Timer::ClearTimer(this, n"StopFilterFXDelayed");

		if(FilterFX != nullptr)
		{
			FilterFXInstance = Audio::StartAudioEffectControlled(this, FilterFX);
			FXFadeAlpha = FXCrossfadeDuration;
			FilterRTPC = BoomBox.ActivePlayer.IsMio() ? MioFilterRTPC : ZoeFilterRTPC;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(FilterFXInstance.IsValid())
		{
			const float CurrAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(0.0, FXCrossfadeDuration), FXFadeAlpha);
			AudioComponent::SetGlobalRTPC(FilterRTPC, CurrAlpha);			
			FXFadeAlpha -= DeltaSeconds;			
		}
	}

	UFUNCTION(BlueprintCallable)
	void StopFilterFX()
	{
		if(FilterFX != nullptr)
		{
			AudioComponent::SetGlobalRTPC(FilterRTPC, 1.0, 1000);		
			Timer::SetTimer(this, n"StopFilterFXDelayed", 1.0);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StopFilterFXDelayed()
	{
		if(FilterFXInstance.IsValid())
		{
			FilterFXInstance.Release();
			FilterFXInstance = FHazeAudioRuntimeEffectInstance();
		}
	}
}