class UTundraPlayerSnowMonkeyIceKingBossPunchSlowMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunch);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;
	UTundraPlayerSnowMonkeyComponent MonkeyComp;
	bool bTimeDilationDone = false;
	FHazeAcceleratedFloat AcceleratedTimeDilation;
	bool bCalledExitEvent = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BossPunchComp.bWithinSlowMotionWindow)
			return false;

		// We don't want any slow motion in the final punch!
		if(BossPunchComp.CurrentBossPunchInteractionActor.Type == ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bTimeDilationDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedTimeDilation.SnapTo(1.0);
		bTimeDilationDone = false;
		bCalledExitEvent = false;

		FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams Params;
		Params.AccelerationDuration = GetSlowMotionEnterAccelerationDuration();
		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnBossPunchSlowMotionEnter(MonkeyComp.SnowMonkeyActor, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Time::SetWorldTimeDilation(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Value;
		if(BossPunchComp.bWithinSlowMotionWindow)
		{
			Value = AcceleratedTimeDilation.AccelerateTo(0.0, GetSlowMotionEnterAccelerationDuration(), DeltaTime);
		}
		else
		{
			Value = AcceleratedTimeDilation.AccelerateTo(1.0, GetSlowMotionExitAccelerationDuration(), DeltaTime);
			if(Math::IsNearlyEqual(AcceleratedTimeDilation.Value, 1.0))
				bTimeDilationDone = true;

			if(!bCalledExitEvent)
			{
				bCalledExitEvent = true;
				OnExit();
			}
		}

		Time::SetWorldTimeDilation(Value);
	}

	void OnExit()
	{
		FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams Params;
		Params.AccelerationDuration = GetSlowMotionExitAccelerationDuration();
		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnBossPunchSlowMotionExit(MonkeyComp.SnowMonkeyActor, Params);
	}

	float GetSlowMotionEnterAccelerationDuration() const
	{
		return BossPunchComp.SlowMotionWindowLength;
	}

	float GetSlowMotionExitAccelerationDuration() const
	{
		return 0.1;
	}
}