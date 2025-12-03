enum ESkylineBallBossBlinkExpression
{
	StateOpen,
	StateSus,
	StateAngry,
	StateSquint,
	QuickBlink,
	QuickWince,
	RemoveDetonator,
	None
}

enum ESkylineBallBossBlinkPriority
{
	Unassigned,
	Lowest,
	Low,
	Med,
	High,
	Higher,
	Highest,
}

struct FBallBossBlink
{
	FInstigator Requester;
	ESkylineBallBossBlinkExpression BlinkType;
	ESkylineBallBossBlinkPriority Priority = ESkylineBallBossBlinkPriority::Lowest;
}

class USkylineBallBossBlinkCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	const float ClosedAngle = 0.0;
	const float OpenAngle = 15.0;

	const float SusUpperAngle = 3.0;
	const float SusLowerAngle = 7.0;

	const float AngryUpperAngle = 0.0;
	const float AngryLowerAngle = 15.0;

	const float WinceUpperAngle = 1.0;
	const float WinceLowerAngle = 1.0;

	const float StateInterpDuration = 0.3;
	const float BlinkDuration = 0.1;
	const float WinceDuration = 2.5;

	ASkylineBallBossAttachedDetonator EventDetonator = nullptr;
	int TimesRemoveToBlink = 3;
	int BlinkTimes = 0;
	bool bFirstRemoveBlink = true;
	bool bLastOpen = true;

	float ClampedUpperAngle = ClosedAngle;
	float ClampedLowerAngle = ClosedAngle;

	FHazeAcceleratedFloat AccUpper;
	FHazeAcceleratedFloat AccLower;

	ESkylineBallBossBlinkExpression CurrentExpression;
	float BlinkCooldown = -1.0;
	float BlinkTimer = 0.0;
	bool bAddedBlink = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BallBoss.RemoveDetonatorBlinkCloseTimelike.BindUpdate(this, n"BlinkTimelikeUpdate");
		BallBoss.RemoveDetonatorBlinkOpenTimelike.BindUpdate(this, n"BlinkTimelikeUpdate");
		BallBoss.RemoveDetonatorBlinkCloseTimelike.BindFinished(this, n"CloseFinished");
		BallBoss.RemoveDetonatorBlinkOpenTimelike.BindFinished(this, n"OpenFinished");
		SkylineBallBossDevToggles::DrawBlinks.MakeVisible();
	}

	UFUNCTION()
	private void CloseFinished()
	{
		if (CurrentExpression != ESkylineBallBossBlinkExpression::RemoveDetonator)
			return;

		if (EventDetonator != nullptr)
			EventDetonator.BlinkImpact();

		BallBoss.RemoveDetonatorBlinkOpenTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void OpenFinished()
	{
		if (CurrentExpression != ESkylineBallBossBlinkExpression::RemoveDetonator)
			return;

		++BlinkTimes;
		if (BlinkTimes > TimesRemoveToBlink)
		{
			ResetRemoveBlink();
			Timer::SetTimer(this, n"StartTimelikeCloseBlink", Math::RandRange(BallBoss.MinRandPauseDuration, BallBoss.MaxRandPauseDuration));
		}
		else
			BallBoss.RemoveDetonatorBlinkCloseTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void BlinkTimelikeUpdate(float CurrentValue)
	{
		if (CurrentExpression != ESkylineBallBossBlinkExpression::RemoveDetonator)
			return;

		CalculateDetonatorClampedAngles();
		AccUpper.SnapTo(Math::Lerp(ClampedUpperAngle, OpenAngle, CurrentValue));
		AccLower.SnapTo(Math::Lerp(ClampedLowerAngle * -1.0, OpenAngle * -1.0, CurrentValue));
	}

	void ResetRemoveBlink()
	{
		TimesRemoveToBlink = Math::RandRange(BallBoss.MinRandBlinks, BallBoss.MaxRandBlinks);
		BlinkTimes = 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	void AddBlink()
	{
		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::QuickBlink, ESkylineBallBossBlinkPriority::Low);
		BlinkCooldown = Math::RandRange(Settings.BlinkCooldownMin, Settings.BlinkCooldownMax);
		bAddedBlink = true;
		BlinkTimer = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentExpression = BallBoss.GetBlink();
		AccUpper.SnapTo(BallBoss.EyeLidUpperMeshComp.RelativeRotation.Pitch);
		AccLower.SnapTo(BallBoss.EyeLidLowerMeshComp.RelativeRotation.Pitch);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentExpression = BallBoss.GetBlink();
		BlinkTimer += DeltaTime;

		if (SkylineBallBossDevToggles::DrawBlinks.IsEnabled())
		{
			FString Texty = "Blink: " + CurrentExpression;
			Debug::DrawDebugString(BallBoss.ActorLocation + BallBoss.ActorForwardVector * 1000.0, Texty);
		}

		bool bInDetonatorMode = CurrentExpression == ESkylineBallBossBlinkExpression::RemoveDetonator;
		if (bInDetonatorMode)
		{
			if (bFirstRemoveBlink)
			{
				bFirstRemoveBlink = false;
				ResetRemoveBlink();
				Timer::SetTimer(this, n"StartTimelikeCloseBlink", BallBoss.RemoveBlinkFirstOpenDuration);
			}
			if (!BallBoss.RemoveDetonatorBlinkCloseTimelike.IsPlaying() && !BallBoss.RemoveDetonatorBlinkOpenTimelike.IsPlaying())
			{
				AccUpper.AccelerateTo(OpenAngle, BallBoss.RemoveBlinkFirstOpenDuration, DeltaTime);
				AccLower.AccelerateTo(OpenAngle * -1.0, BallBoss.RemoveBlinkFirstOpenDuration, DeltaTime);	
			}
		}
		else
		{
			EventDetonator = nullptr;
			bFirstRemoveBlink = true;
			float UpperTarget = GetUpperTarget();
			float LowerTarget = GetLowerTarget() * -1.0;
			float Duration = GetDuration();
			AccUpper.AccelerateTo(UpperTarget, Duration, DeltaTime);
			AccLower.AccelerateTo(LowerTarget, Duration, DeltaTime);
		}

		FRotator UpperRot = FRotator::MakeFromEuler(FVector(0.0, AccUpper.Value, 0.0));
		BallBoss.EyeLidUpperMeshComp.SetRelativeRotation(UpperRot);
		FRotator LowerRot = FRotator::MakeFromEuler(FVector(0.0, AccLower.Value, 0.0));
		BallBoss.EyeLidLowerMeshComp.SetRelativeRotation(LowerRot);

		ESkylineBallBossBlinkExpression BossExpression = BallBoss.GetBlink();
		if (bAddedBlink)
		{
			if (BossExpression != ESkylineBallBossBlinkExpression::QuickBlink)
			{
				BallBoss.RemoveBlink(this);
				bAddedBlink = false;
			}
			else if (!bInDetonatorMode && BlinkTimer > BlinkDuration)
			{
				BallBoss.RemoveBlink(this);
				bAddedBlink = false;
				if (Math::RandRange(0.0, 1.0) < Settings.DoubleBlinkChance)
					Timer::SetTimer(this, n"DelayedDoubleBlink", BlinkDuration * 2.0);
			}
		}
		else if (!bInDetonatorMode && BlinkTimer > BlinkCooldown)
			AddBlink();

		CurrentExpression = BossExpression;
	}

	UFUNCTION()
	private void StartTimelikeCloseBlink()
	{
		BallBoss.RemoveDetonatorBlinkCloseTimelike.PlayFromStart();
	}

	UFUNCTION()
	void DelayedDoubleBlink()
	{
		AddBlink();
	}

	float GetUpperTarget()
	{
		switch (CurrentExpression)
		{
			case ESkylineBallBossBlinkExpression::StateOpen:
				return OpenAngle;
			case ESkylineBallBossBlinkExpression::StateSus:
				return SusUpperAngle;
			case ESkylineBallBossBlinkExpression::StateAngry:
				return AngryUpperAngle;
			case ESkylineBallBossBlinkExpression::StateSquint:
				return WinceUpperAngle;
			case ESkylineBallBossBlinkExpression::QuickWince:
				return WinceUpperAngle;
			case ESkylineBallBossBlinkExpression::QuickBlink:
				return ClosedAngle;
			case ESkylineBallBossBlinkExpression::RemoveDetonator:
				return ClosedAngle;
			case ESkylineBallBossBlinkExpression::None:
				return ClosedAngle;
		}
	}

	float GetLowerTarget()
	{
		switch (CurrentExpression)
		{
			case ESkylineBallBossBlinkExpression::StateOpen:
				return OpenAngle;
			case ESkylineBallBossBlinkExpression::StateSus:
				return SusLowerAngle;
			case ESkylineBallBossBlinkExpression::StateAngry:
				return AngryLowerAngle;
			case ESkylineBallBossBlinkExpression::StateSquint:
				return WinceLowerAngle;
			case ESkylineBallBossBlinkExpression::QuickWince:
				return WinceLowerAngle;
			case ESkylineBallBossBlinkExpression::QuickBlink:
				return ClosedAngle;
			case ESkylineBallBossBlinkExpression::RemoveDetonator:
				return ClosedAngle;
			case ESkylineBallBossBlinkExpression::None:
				return ClosedAngle;
		}
	}

	float GetDuration()
	{
		switch (CurrentExpression)
		{
			case ESkylineBallBossBlinkExpression::QuickWince:
				return WinceDuration;
			case ESkylineBallBossBlinkExpression::QuickBlink:
				return BlinkDuration;
			default:
				return StateInterpDuration;
		}
	}

	void CalculateDetonatorClampedAngles()
	{
		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			ClampAnglesByDetonator(BallBoss.DetonatorSocketComp1.AttachedDetonator);
		if (BallBoss.DetonatorSocketComp2.AttachedDetonator != nullptr)
			ClampAnglesByDetonator(BallBoss.DetonatorSocketComp2.AttachedDetonator);
		if (BallBoss.DetonatorSocketComp3.AttachedDetonator != nullptr)
			ClampAnglesByDetonator(BallBoss.DetonatorSocketComp3.AttachedDetonator);
	}

	void ClampAnglesByDetonator(ASkylineBallBossAttachedDetonator Detonator)
	{
		FVector RelativeLoc = Detonator.ActorRelativeLocation;
		RelativeLoc.Y = 0.0; // we don't care about right/left offsetedness
		FRotator LocalRotationPosition = FRotator::MakeFromXZ(RelativeLoc.GetSafeNormal(), FVector::UpVector);
		const float DetonatorRadiusInDegrees = 2.0;
		const float PreviousUpperAngle = ClampedUpperAngle;
		const float PreviousLowerAngle = ClampedLowerAngle;
		ClampedUpperAngle = Math::Max(ClampedUpperAngle, LocalRotationPosition.Pitch + DetonatorRadiusInDegrees);
		ClampedLowerAngle = Math::Max(ClampedLowerAngle, LocalRotationPosition.Pitch + DetonatorRadiusInDegrees);

		if (ClampedUpperAngle > PreviousUpperAngle || ClampedLowerAngle > PreviousLowerAngle)
			EventDetonator = Detonator;
	}
}