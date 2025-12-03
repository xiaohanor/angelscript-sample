
class UBattlefieldHoverboardBigAirPlayerCapability : UHazePlayerCapability
{
	UBattlefieldHoverboardBigAirPlayerComponent BigAirComponent;
	UBattlefieldHoverboardComponent HoverboardComponent;

	FBattlefieldHoverboardBigAirInstigatorData BigAirData;
	FHazeAudioRuntimeEffectInstance RuntimeEffectInstance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BigAirComponent = UBattlefieldHoverboardBigAirPlayerComponent::GetOrCreate(Player);
		HoverboardComponent = UBattlefieldHoverboardComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if(HoverboardComponent.bIsGrounded)
		// 	return false;

		if(BigAirComponent.InstigatedBigAirData.IsSet() == false)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BigAirData = BigAirComponent.InstigatedBigAirData.GetValue();

		auto System = Game::GetSingleton(UHazeAudioRuntimeEffectSystem);
		RuntimeEffectInstance = System.StartControlled(this, BigAirData.EffectShareset);			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		const FVector Start = Player.ActorLocation;
		const FVector End = Start + (Player.ActorForwardVector * BigAirData.GroundedTraceLength);

		#if TEST
			Trace.DebugDrawOneFrame();
		#endif

		auto Result = Trace.QueryTraceSingle(Start, End);
		if(Result.bBlockingHit)
		{
			BigAirComponent.InstigatedBigAirData.Reset();
		}
		else
		{
			const float Alpha = Math::Saturate(ActiveDuration / BigAirData.InterpolationTime);
			RuntimeEffectInstance.SetAlpha(1 - Alpha);
		}
	}
}