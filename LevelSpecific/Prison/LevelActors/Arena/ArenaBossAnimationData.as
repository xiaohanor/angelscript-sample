struct FArenaBossAnimationData
{
	FVector2D MoveDirection;
	float ThrusterAlpha = 1.0;

	bool bEnteringState = false;
	bool bExitingState = false;

	bool bLaunchingBombs = false;

	bool bFlameThrowerLeftHand = false;
	bool bSweepingFlameThrower = false;

	bool bLaunchingFist = false;

	bool bLeftHandSmash = true;
	bool bSkipSmashEnter = true;
	bool bSmashing = false;

	bool bPlatformBreakStateEnter = false;
	EArenaBossPlatformAttackState PlatformAttackState;

	bool bFacePunchFromSmash = false;
	bool bPunchingFace = false;
	bool bExitingFacePunch = false;
	bool bLosingHand = false;

	bool bHacked = false;
	float HackedPunchCharge = 0.0;
	bool bHackedPunch = false;
	bool bFinalPunch = false;

	bool bRightHandRemoved = false;

	EArenaBossArmSmashState ArmSmashState;

	bool bBatting = false;

	bool bThrusterBlasting = false;

	bool bInPositionForLaser = false;
	bool bLaserLeft = true;
	float LaserPlayRate = 1.0;
	bool bLaserOverheat = false;

	float HeadHackCharge = 0.0;
	bool bHeadPoppedOff = false;
	bool bHeadMagnetized = false;
}