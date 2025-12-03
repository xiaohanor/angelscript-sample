struct FMoonMarketHarpPlayingDeactivationParams
{
	bool bWasInterrupted;
}

class UMoonGuardianHarpPlayingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	UMoonGuardianHarpPlayingComponent HarpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HarpComp = UMoonGuardianHarpPlayingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HarpComp.bShouldExit)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMoonMarketHarpPlayingDeactivationParams& Params) const
	{
		Params.bWasInterrupted = HarpComp.bShouldExit;

		if(HarpComp.bShouldExit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"InteractionCancel", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FMoonMarketHarpPlayingDeactivationParams Params)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if(Params.bWasInterrupted && HarpComp.Harp != nullptr)
			HarpComp.Harp.StopInteraction(HarpComp.Harp.InteractingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		const float TimeSinceSuccess = Time::GetGameTimeSince(HarpComp.HarpSuccessTime);
		float Length = 0.5;
		if(TimeSinceSuccess < Length)
		{
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = (1 - Length) - (TimeSinceSuccess / Length);
			FF.RightMotor = (TimeSinceSuccess / Length) - (1 - Length);
			Player.SetFrameForceFeedback(FF, 0.2);
		}

		if(HarpComp.bShouldExit)
			return;

		if(HarpComp.ExitDuration > 0)
		{
			HarpComp.ExitDuration -= DeltaTime;
			if(HarpComp.ExitDuration <= 0)
			{
				HarpComp.bShouldExit = true;
			}

			return;
		}

		if(HarpComp.NoteTimer / HarpComp.CurrentNoteDuration < 0.2)
			return;

		if(WasActionStarted(ActionNames::RhythmGameUp))
			HarpComp.PlayNote(EMoonGuardianHarpNote::Up);

		if(WasActionStarted(ActionNames::RhythmGameLeft))
			HarpComp.PlayNote(EMoonGuardianHarpNote::Left);

		if(Player.IsUsingGamepad())
		{
		if(WasActionStarted(ActionNames::RhythmGameDown))
			HarpComp.PlayNote(EMoonGuardianHarpNote::Down);
		}
		else
		{
			if(WasActionStarted(ActionNames::RhythmGameRight))
				HarpComp.PlayNote(EMoonGuardianHarpNote::Down);
		}

	}
};