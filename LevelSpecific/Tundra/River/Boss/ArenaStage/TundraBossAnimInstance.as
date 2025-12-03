class UTundraBossAnimInstance : UHazeAnimInstanceBase
{
	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData IntroIceKing;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData Idle;

	UPROPERTY(Category = "IceKing")
	FHazePlayRndSequenceData IdleRandom;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ClawScrape;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ClawScrapeShort;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData Scream;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData AreaSlamStart;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData AreaSlamHold;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData IceCrack;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData HitBall;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData HitBallMH;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData HitBallBackToIdle;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData AreaSlamEnd;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ExposedConnectEnd;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ExposedLoop;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ExposedStrike;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ExposedBackToMH;
	
	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData WallJump;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData IceKingMH;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData CircleRunSlow;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData CloseAttack;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ScreamSlamStart;
	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData RedIceMagic;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData BeforeChargeAttack;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ChargeAttack;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData ExposedConnectLoopStart;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData AttackFurBall;

	UPROPERTY(Category = "IceKing")
	FHazePlaySequenceData Whirlwind;

	UPROPERTY(Category = "Defeat")
	FHazePlaySequenceData HitBallFinal;

	UPROPERTY(Category = "Defeat")
	FHazePlaySequenceData HitBallFinalMH;

	UPROPERTY(Category = "Defeat")
	FHazePlaySequenceData FinalApeHit_Var1;

	UPROPERTY(Category = "Defeat")
	FHazePlaySequenceData FinalApeHit_Var2;

	UPROPERTY(Category = "Defeat")
	FHazePlaySequenceData FinalApeHit_Var3;

	UPROPERTY(Category = "Defeat")
	FHazePlaySequenceData FinalApeHit_Var4;

	UPROPERTY(Category = "BossPunchFirstTime")
	FHazePlaySequenceData Punch1;

	UPROPERTY(Category = "BossPunchFirstTime")
	FHazePlaySequenceData Punch2;

	UPROPERTY(Category = "BossPunchFirstTime")
	FHazePlaySequenceData Punch3;

	UPROPERTY(Category = "BossPunchFirstTime")
	FHazePlaySequenceData Punch4;

	UPROPERTY(Category = "BossPunchFirstTime")
	FHazePlaySequenceData Punch5;

	UPROPERTY(Category = "BossPunchFirstTime")
	FHazePlaySequenceData Punch6;

	UPROPERTY(Category = "BossPunchSecondTime")
	FHazePlaySequenceData Punch1Phase03;

	UPROPERTY(Category = "BossPunchSecondTime")
	FHazePlaySequenceData Punch2Phase03;

	UPROPERTY(Category = "BossPunchSecondTime")
	FHazePlaySequenceData Punch3Phase03;

	UPROPERTY(Category = "BossPunchSecondTime")
	FHazePlaySequenceData Punch4Phase03;

	UPROPERTY(Category = "BossPunchSecondTime")
	FHazePlaySequenceData Punch5Phase03;

	UPROPERTY(Category = "BossPunchSecondTime")
	FHazePlaySequenceData Punch6Phase03;

	UPROPERTY(Category = "BossPunchFinal")
	FHazePlaySequenceData Punch01Final;

	UPROPERTY(Category = "BossPunchFinal")
	FHazePlaySequenceData Punch02Final;

	UPROPERTY(Category = "BossPunchFinal")
	FHazePlaySequenceData FinalMH;

	UPROPERTY(Category = "HitBySphere")
	FHazePlaySequenceData HitBySphere;

	UPROPERTY(Category = "HitBySphere")
	FHazePlaySequenceData HitBySphereMH;

	UPROPERTY(Category = "HitBySphere")
	FHazePlaySequenceData GetBackUpFinal;

	UPROPERTY(Category = "IceKingExposedLoopBS")
	FHazePlayBlendSpaceData StruggleBS;

	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData FinalPunchHitReaction01;
	
	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData FinalPunchHitReaction02;
	
	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData FinalPunchHitReaction03;

	UPROPERTY()
	float DefaultStateBlendOutTime = 0.2;

	UPROPERTY()
	ETundraBossAttackAnim RequestedAnimation;

	UPROPERTY()
	bool bGrabbed = false;

	UPROPERTY()
	float StruggleBlendSpaceValue;

	UPROPERTY()
	bool bPunchingThisFrame = false;

	UPROPERTY()
	bool bShouldPlayLastFinalPunch = false;

	UPROPERTY()
	bool bFinalPunchThisFrame = false;

	bool bShouldTickFinalPunchTimer = false;
	float FinalPunchTimer = 0;
	float FinalPunchTimerDuration = 0.63;

	UPROPERTY()
	bool bInstantSpawn;
	UPROPERTY()
	bool bStartActualCharge = false;
	UPROPERTY()
	bool bExitIceKingAnimation = false;

	UPROPERTY()
	int AmountOfPunches = 0;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		bStartActualCharge = GetAnimBoolParam(n"StartActualCharge", true, false);
		bExitIceKingAnimation = GetAnimBoolParam(n"ExitIceKingAnimation", true, false);
	}

	UFUNCTION()
	float GetTundraBossAnimationDuration(ETundraBossAttackAnim AnimationState)
	{
		switch(AnimationState)
		{
			case ETundraBossAttackAnim::Spawn:
				return IntroIceKing.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::Idle:
				return Idle.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::ClawAttack:
				return ClawScrape.Sequence.GetPlayLength() / ClawScrape.Sequence.GetRateScale(); //Remove when animation is adjusted without rate scale.
			case ETundraBossAttackAnim::ClawAttackShort:
				return ClawScrapeShort.Sequence.GetPlayLength() / ClawScrapeShort.Sequence.GetRateScale(); //Remove when animation is adjusted without rate scale.
			case ETundraBossAttackAnim::Wallrun:
				return WallJump.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::TriggerFallingIcicles:
				return Scream.Sequence.GetPlayLength() / Scream.Sequence.GetRateScale(); //Remove when animation is adjusted without rate scale.
			case ETundraBossAttackAnim::TriggerRedIce:
				return RedIceMagic.Sequence.GetPlayLength(); //Remove when animation is adjusted without rate scale.
			case ETundraBossAttackAnim::RingsOfIce:
				return AreaSlamStart.Sequence.GetPlayLength() + AreaSlamEnd.Sequence.GetPlayLength(); //Could probably be combined into one animation...
			case ETundraBossAttackAnim::GetBackUp:
				return ExposedBackToMH.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::GetBackUpFromStruggle:
				return ExposedBackToMH.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::GetBackUpPhase03:
				return GetBackUpFinal.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::CloseAttack:
				return CloseAttack.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::FurBall:
				return AttackFurBall.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::Whirlwind:
				return Whirlwind.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::HitBySphere:
				return Whirlwind.Sequence.GetPlayLength();
			case ETundraBossAttackAnim::ChargeAttack:
				return ChargeAttack.Sequence.GetPlayLength();
			default:
				return 0;
		}
	}
}

enum ETundraBossAttackAnim
{
	Spawn,
	Hidden,
	Idle,
	ClawAttack,
	ClawAttackShort,
	Wallrun,
	TriggerFallingIcicles,
	TriggerRedIce,
	RingsOfIce,
	HitReaction,
	Struggle,
	Grabbed,
	GetBackUp,
	GetBackUpFromStruggle,
	GetBackUpPhase03,
	Wait,
	CloseAttack,
	FurBall,
	Whirlwind,
	HitBySphere,
	HitBySphereSecondTime,
	ChargeAttack
}

enum ETundraBossIceBreatheDirection
{
	Center,
	Right,
	Left
}