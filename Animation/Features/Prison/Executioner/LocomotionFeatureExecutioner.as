struct FLocomotionFeatureExecutionerAnimData
{
	
	UPROPERTY(Category = "Executioner|MH")
	FHazePlaySequenceData MH;


	UPROPERTY(Category = "Executioner|Additive")
	FHazePlaySequenceData HipsAdditive;

	
	UPROPERTY(Category = "Executioner|Thrusters")
	FHazePlayBlendSpaceData ThrustersBS;

	UPROPERTY(Category = "Executioner|Thrusters")
	FHazePlaySequenceData ThrustersAttackEnter;

	UPROPERTY(Category = "Executioner|Thrusters")
	FHazePlayBlendSpaceData ThrustersAttackBS;

	UPROPERTY(Category = "Executioner|Thrusters")
	FHazePlaySequenceData ThrustersAttackBlast;

	UPROPERTY(Category = "Executioner|Thrusters")
	FHazePlaySequenceData ThrustersAttackExit;


	UPROPERTY(Category = "Executioner|Bombs")
	FHazePlaySequenceData BombsEnter;

	UPROPERTY(Category = "Executioner|Bombs")
	FHazePlaySequenceData BombsMH;

	UPROPERTY(Category = "Executioner|Bombs")
	FHazePlaySequenceData BombsLaunch;

	UPROPERTY(Category = "Executioner|Bombs")
	FHazePlaySequenceData BombsExit;


	UPROPERTY(Category = "Executioner|Discs")
	FHazePlaySequenceData DiscsEnter;

	UPROPERTY(Category = "Executioner|Discs")
	FHazePlaySequenceData DiscsMH;

	UPROPERTY(Category = "Executioner|Discs")
	FHazePlaySequenceData DiscsLaunch;

	UPROPERTY(Category = "Executioner|Discs")
	FHazePlaySequenceData DiscsExit;


	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameLeftEnter;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameLeftShootMH;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameLeftShoot;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameLeftExit;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameLeftToRight;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameRightEnter;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameRightShoot;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameRightShootMH;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameRightExit;

	UPROPERTY(Category = "Executioner|Flame")
	FHazePlaySequenceData FlameRightToLeft;


	UPROPERTY(Category = "Executioner|Punch")
	FHazePlaySequenceData PunchEnter;

	UPROPERTY(Category = "Executioner|Punch")
	FHazePlaySequenceData PunchMH;

	UPROPERTY(Category = "Executioner|Punch")
	FHazePlaySequenceData PunchLaunch;

	UPROPERTY(Category = "Executioner|Punch")
	FHazePlaySequenceData PunchExit;


	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformEnter;

	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformMH;

	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformBlast;

	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformBreakEnter;

	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformBreakMH;

	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformBreak;

	UPROPERTY(Category = "Executioner|Platform")
	FHazePlaySequenceData PlatformExit;


	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsLeftEnter;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsLeftMH;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsLeftSmash;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsLeftExit;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsRightEnter;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsRightMH;
	
	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsRightSmash;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsRightSmashToRightMH;

	UPROPERTY(Category = "Executioner|Fists")
	FHazePlaySequenceData FistsRightExit;


	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceLeftEnter;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceLeftEnterFromSmash;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceLeftMH;
	
	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceLeftPunch;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceLeftExit;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceLeftLoseHand;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceRightEnter;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceRightEnterFromSmash;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceRightMH;
	
	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceRightPunch;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceRightExit;

	UPROPERTY(Category = "Executioner|Face")
	FHazePlaySequenceData FaceRightLoseHand;


	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedLeftStunned;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedLeftEnter;
	
	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedLeftMH;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlayBlendSpaceData HackedLeftCharge;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedLeftPunch;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedLeftLastPunch;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedRightStunned;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedRightEnter;
	
	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedRightMH;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlayBlendSpaceData HackedRightCharge;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedRightPunch;

	UPROPERTY(Category = "Executioner|Hacked")
	FHazePlaySequenceData HackedRightLastPunch;


	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmRip;
	
	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmMH;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmSmashEnter;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmSmashMH;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmSmashAttack;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmSmashExit;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmBatEnter;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmBatMH;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmBatAttack;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmBatExit;

	UPROPERTY(Category = "Executioner|Arm")
	FHazePlaySequenceData ArmLoseArm;


	UPROPERTY(Category = "Executioner|Laser")
	FHazePlaySequenceData LaserEnter;

	UPROPERTY(Category = "Executioner|Laser")
	FHazePlaySequenceData LaserLeftToRight;

	UPROPERTY(Category = "Executioner|Laser")
	FHazePlaySequenceData LaserRightToLeft;

	UPROPERTY(Category = "Executioner|Laser")
	FHazePlaySequenceData LaserOverheat;

	UPROPERTY(Category = "Executioner|Laser")
	FHazePlaySequenceData LaserOverheatMH;


	UPROPERTY(Category = "Executioner|HackHead")
	FHazePlaySequenceData HackHeadEnter;

	UPROPERTY(Category = "Executioner|HackHead")
	FHazePlayBlendSpaceData HackHeadPull;

	UPROPERTY(Category = "Executioner|HackHead")
	FHazePlaySequenceData HackHeadLoseHead;

	UPROPERTY(Category = "Executioner|HackHead")
	FHazePlaySequenceData HackHeadLoseHeadMH;

	UPROPERTY(Category = "Executioner|HackHead")
	FHazePlaySequenceData HackHeadLaunch;

}

class ULocomotionFeatureExecutioner : UHazeLocomotionFeatureBase
{
	default Tag = n"Executioner";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureExecutionerAnimData AnimData;
}
