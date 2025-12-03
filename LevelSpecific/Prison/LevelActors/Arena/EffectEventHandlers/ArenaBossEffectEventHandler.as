
UCLASS(Abstract)
class UArenaBossEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AArenaBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AArenaBoss>(Owner);
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnIntensityRequested(FCrowdIntensityRequest RequestParams) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BombStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BombLaunched() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BombStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BombStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiscStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiscLaunched() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiscStateWindDown() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiscStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameThrowerStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameThrowerStarted(FArenaBossFlameThrowerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameThrowerStopped(FArenaBossFlameThrowerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameThrowerStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameThrowerStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchLockOnStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchChargeStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchLaunched() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchReturned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketPunchStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackFlyToPlatformStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackChargeStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackSmashThrough() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackReturnStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformAttackStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashLockOnStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashChargeStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FacePunchStateEntered(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FacePunchHit(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FacePunchFinalHit(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FacePunchStateEnded(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackStateEntered(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHacked(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackStartCharge(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackStopCharge(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackCharged(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackPunch(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackFinalPunch(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackStateEnded(FArenaBossHandData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmSmashStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmSmashAttackSequenceStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmSmashStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmSmashStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatBombStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatBombAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatBombStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatBombStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmThrowStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmThrowAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmThrowStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBlastStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBlast() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBlastStateWindDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrusterBlastStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserEyesStateEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserEyesAttackStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserEyesSweepStarted(FArenaBossLaserEyesSweepData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserEyesOverheat() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserEyesStateEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadHackStateEntered() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadHackedStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadHacked() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadHackPoppedOff() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadHackMagnetBurstStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadHackMagnetBurst() {}
}

struct FArenaBossFlameThrowerData
{
	UPROPERTY()
	bool bRightHand = true;
}

struct FArenaBossHandData
{
	UPROPERTY()
	bool bRightHandRemoved = false;

	UPROPERTY()
	bool bIsFinalPunch = false;
}

struct FArenaBossLaserEyesSweepData
{
	UPROPERTY()
	float CompletionAlpha = 0.0;
}

namespace ArenaCrowdSetting
{
	const float Default = 0.2;
	const float Small = 0.5;
	const float Medium = 0.8;
	const float Large = 1.0;
}

enum EArenaBossCrowdState
{
	Default,
	Small,
	Medium,
	Large
}

struct FCrowdIntensityRequest
{
	// what fractional intensity that has been rquested.
	UPROPERTY()
	float Intensity = ArenaCrowdSetting::Default;

	// what state the intensity translates to
	UPROPERTY()
	EArenaBossCrowdState State = EArenaBossCrowdState::Default;

	// when the state was requested
	UPROPERTY()
	float ActionTimeStamp = -1.0;

	// How long we stay in the requested state,
	//  before we start blending back to default again
	UPROPERTY()
	float Duration = 1.0;

	// How much time needs to elapse, 
	// after the desired intensity has been reached, 
	// before we fall down to Default again
	UPROPERTY()
	float Duration_BlendOut = 0.3;

	// How much time needs to elapse, 
	// after the request has been made,
	// before we reach the state requested 
	UPROPERTY()
	float Duration_BlendIn = 0.3;

	float GetRequestDuration() const
	{
		return (Duration_BlendIn + Duration + Duration_BlendOut);
	}

	bool opEquals(FCrowdIntensityRequest Other) const
	{
		return Equals(Other);
	}

	bool Equals(FCrowdIntensityRequest Other) const
	{
		return 	(Intensity == Other.Intensity) 
		&& (ActionTimeStamp == Other.ActionTimeStamp)
		&& (Duration == Other.Duration)
		&& (Duration_BlendOut == Other.Duration_BlendOut)
		&& (Duration_BlendIn == Other.Duration_BlendIn);
	}
}