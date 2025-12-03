UCLASS(Abstract)
class UFeatureAnimInstanceExecutioner : UHazeAnimInstanceBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY()
	ULocomotionFeatureExecutioner Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureExecutionerAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	AArenaBoss ExecutionerActor;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EArenaBossState CurrentState;
	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitingState = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBombsLaunch = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlameLeftHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlameShoot = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPunchLaunch = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlatformSmash = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlatformBreakStateEnter = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlatformBreak = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFistLeftHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFistSkipEnter = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFistSmash = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFacePunch = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitFacePunch = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLoseHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHackedEnter = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HackedCharge;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHackedPunch = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFinalPunch = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightHandRemoved = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bArmRaising = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bArmSmashing = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBatting = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrusterBlasting = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLaserLeft = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LaserPlayRate = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLaserOverheat = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInPositionForLaser = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HeadHackCharge = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHeadPoppedOff = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHeadMagnetized = false;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightHandIK = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLeftHandIK = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromSmash = false;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D MoveDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ThrusterAlpha = 1.0;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		ExecutionerActor = Cast<AArenaBoss>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (Feature != nullptr)
			AnimData = Feature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		if (ExecutionerActor == nullptr)
			return;

		CurrentState = ExecutionerActor.CurrentState;

		MoveDirection = ExecutionerActor.AnimationData.MoveDirection;

		bExitingState = ExecutionerActor.AnimationData.bExitingState;

		bBombsLaunch = ExecutionerActor.AnimationData.bLaunchingBombs;

		bPunchLaunch = ExecutionerActor.AnimationData.bLaunchingFist;

		bFlameLeftHand = ExecutionerActor.AnimationData.bFlameThrowerLeftHand;
		bFlameShoot = ExecutionerActor.AnimationData.bSweepingFlameThrower;

		bPlatformSmash = ExecutionerActor.AnimationData.PlatformAttackState == EArenaBossPlatformAttackState::Attacking;
		bPlatformBreakStateEnter = ExecutionerActor.AnimationData.bPlatformBreakStateEnter;
		bPlatformBreak = ExecutionerActor.AnimationData.PlatformAttackState == EArenaBossPlatformAttackState::SmashingThrough;

		bFistLeftHand = ExecutionerActor.AnimationData.bLeftHandSmash;
		bFistSkipEnter = ExecutionerActor.AnimationData.bSkipSmashEnter;
		bFistSmash = ExecutionerActor.AnimationData.bSmashing;

		bCameFromSmash = ExecutionerActor.AnimationData.bFacePunchFromSmash;
		bFacePunch = ExecutionerActor.AnimationData.bPunchingFace;
		bExitFacePunch = ExecutionerActor.AnimationData.bExitingFacePunch;
		bLoseHand = ExecutionerActor.AnimationData.bLosingHand;

		bHackedEnter = ExecutionerActor.AnimationData.bHacked;
		HackedCharge = ExecutionerActor.AnimationData.HackedPunchCharge;
		bHackedPunch = ExecutionerActor.AnimationData.bHackedPunch;
		bFinalPunch = ExecutionerActor.AnimationData.bFinalPunch;

		bRightHandRemoved = ExecutionerActor.AnimationData.bRightHandRemoved;

		bArmRaising = ExecutionerActor.AnimationData.ArmSmashState == EArenaBossArmSmashState::RaisingArm;
		bArmSmashing = ExecutionerActor.AnimationData.ArmSmashState == EArenaBossArmSmashState::Smashing;

		bBatting = ExecutionerActor.AnimationData.bBatting;

		bThrusterBlasting = ExecutionerActor.AnimationData.bThrusterBlasting;

		ThrusterAlpha = ExecutionerActor.AnimationData.ThrusterAlpha;

		bInPositionForLaser = ExecutionerActor.AnimationData.bInPositionForLaser;
		bLaserLeft = ExecutionerActor.AnimationData.bLaserLeft;
		LaserPlayRate = ExecutionerActor.AnimationData.LaserPlayRate;
		bLaserOverheat = ExecutionerActor.AnimationData.bLaserOverheat;

		HeadHackCharge = ExecutionerActor.AnimationData.HeadHackCharge;
		bHeadPoppedOff = ExecutionerActor.AnimationData.bHeadPoppedOff;
		bHeadMagnetized = ExecutionerActor.AnimationData.bHeadMagnetized;
	}

	UFUNCTION()
	void AnimNotify_DisableRightHandIK()
	{
		bRightHandIK = false;
	}

	UFUNCTION()
	void AnimNotify_EnableRightHandIK()
	{
		bRightHandIK = true;
	}

	UFUNCTION()
	void AnimNotify_DisableLeftHandIK()
	{
		bLeftHandIK = false;
	}

	UFUNCTION()
	void AnimNotify_EnableLeftHandIK()
	{
		bLeftHandIK = true;
	}

	UFUNCTION()
	void AnimNotify_DisableIK()
	{
		bRightHandIK = false;
		bLeftHandIK = false;
	}


}
