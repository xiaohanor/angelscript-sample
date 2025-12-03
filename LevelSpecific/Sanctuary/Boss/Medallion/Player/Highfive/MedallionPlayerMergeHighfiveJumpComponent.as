event void FMedallionHighfiveStarted();

class UMedallionPlayerMergeHighfiveJumpComponent : UActorComponent
{
	private bool bIsHighfiveJumping = false;

	access ReadOnly = private, * (readonly), 
		UMedallionPlayerMergeHighfiveResetCapability, 
		UMedallionPlayerMergeHighfiveSuccessOrFailCapability, 
		UMedallionPlayerMergeHighfiveAllowstartCapability, 
		UMedallionPlayerMergeHighfiveActiveCapability,
		UMedallionPlayerTriggerFlyingCapability,
		UMedallionPlayerMergingHighfiveHoldCapability;

	access:ReadOnly bool bHighfiveJumpStartTriggered = false;
	access:ReadOnly bool bHighfiveResolveTriggered = false;
	access:ReadOnly bool bHighfiveSuccess = false;
	access:ReadOnly bool bAllowHighfiveJumpStart = true;
	access:ReadOnly bool bAllowFlying = false;
	private float HighfiveTimestamp = 0.0;
	access:ReadOnly float HighfiveHoldAlpha = 0.0;
	access:ReadOnly float PingLenience = 0.0;
	access:ReadOnly bool bGameOvering = false;

	FMedallionHighfiveStarted OnHighfiveStart;

	bool IsHighfiveJumping() const
	{
		return bIsHighfiveJumping;
	}

	void StartHighfiveJumping(float HostPing)
	{
		HighfiveTimestamp = Time::GameTimeSeconds;
		bIsHighfiveJumping = true;
		bAllowHighfiveJumpStart = false;
		PingLenience = HostPing;
		OnHighfiveStart.Broadcast();
	}

	void StopHighfiveJumping()
	{
		bIsHighfiveJumping = false;
	}

	bool AllowHighfiveJumpStart() const
	{
		return bAllowHighfiveJumpStart;
	}

	void ResetHighfiveJumpStart()
	{
		bAllowHighfiveJumpStart = true;
	}

	float GetHighfiveJumpDuration() const
	{
		if (Network::IsGameNetworked()) 
			return MedallionConstants::Highfive::HighfiveJumpDuration + Math::Clamp(PingLenience, 0.0, MedallionConstants::Highfive::HighPingNetworkMaxSeconds);
		return MedallionConstants::Highfive::HighfiveJumpDuration;
	}

	float GetHighfiveJumpTriggerDistance() const
	{
		if (Network::IsGameNetworked()) 
		{
			float BaseDistance = MedallionConstants::Highfive::TriggerHighfiveJumpDistance;
			float PingyAlpha = Math::Saturate(PingLenience / MedallionConstants::Highfive::HighPingNetworkMaxSeconds);
			float ExtraDistance = Math::Lerp(0.0, MedallionConstants::Highfive::HighPingNetworkExtraJumpDistance, PingyAlpha);
			return BaseDistance + ExtraDistance;
		}
		return MedallionConstants::Highfive::TriggerHighfiveJumpDistance;
	}

	bool IsInHighfiveSuccess() const
	{
		return bHighfiveResolveTriggered && bHighfiveSuccess;
	}

	bool IsInHighfiveFail() const
	{
		return bHighfiveResolveTriggered && !bHighfiveSuccess;
	}

	float GetHighfiveJumpProgressAlpha() const
	{
		if (!bIsHighfiveJumping)
			return 0.0;
		const float HighfiveTimer = Time::GameTimeSeconds - HighfiveTimestamp;
		const float HighfiveDuration = GetHighfiveJumpDuration();
		return Math::Saturate(HighfiveTimer / HighfiveDuration);
	}

	bool CanCompleteHighfive() const
	{
		if (!bIsHighfiveJumping || bHighfiveResolveTriggered)
			return false;
		float HighfiveTimer = Time::GameTimeSeconds - HighfiveTimestamp;
		float TimeLeft = Math::Clamp(GetHighfiveJumpDuration() - HighfiveTimer, 0.0, GetHighfiveJumpDuration());
		float MyProgress = Game::Mio.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
		float YourProgress = Game::Zoe.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
		float LeastProgress = Math::Min(MyProgress, YourProgress);
		float TimeLeftToHold = MedallionConstants::Highfive::HighfiveHoldDuration - MedallionConstants::Highfive::HighfiveHoldDuration * LeastProgress;
		// PrintToScreen("timeleft to hold : " + Math::TruncFloatDecimals(TimeLeftToHold, 2) + "/" + TimeLeft);
		return TimeLeftToHold <= TimeLeft;
	}

	bool WillProbablyCompleteHighfive() const
	{
		float MyProgress = Game::Mio.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
		float YourProgress = Game::Zoe.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
		return Math::IsNearlyEqual(MyProgress, 1.0, KINDA_SMALL_NUMBER) && Math::IsNearlyEqual(YourProgress, 1.0, KINDA_SMALL_NUMBER);
	}
};