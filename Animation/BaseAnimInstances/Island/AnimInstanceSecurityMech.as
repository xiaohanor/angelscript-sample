namespace FeatureTagIslandSecurityMech
{
	const FName Locomotion = n"Locomotion";
		
	const FName LaserShot = n"Laser";
	
	const FName BullitShot = n"Bullit";
	
	const FName RocketShot = n"RocketShot";
	
	const FName AimingRocket = n"AimingRocket";

	const FName LaserStart = n"LaserStart";

	const FName LaserEnd = n"LaserEnd";

	const FName GunPose = n"GunPose";

	const FName SwingAttack = n"SwingAttack";

	const FName HitReaction = n"HitReaction";

	const FName SmallHitReaction = n"SmallHitReaction";

	const FName LaunchRocket = n"LaunchRocket";

	const FName Stunned = n"Stunned";

	const FName Death = n"Death";

	const FName StartFlyDeath = n"StartFlyDeath";

	const FName FlyDeath = n"FlyDeath";

	const FName Reload = n"Reload";

	const FName AirAttack = n"AirAttack";

	const FName JumpUp = n"JumpUp";
	
	const FName JumpDown = n"JumpDown";
	
	const FName Land = n"Land";
	
	const FName BlastAttackCharge = n"BlastAttackCharge";
	
	const FName BlastAttackRelease = n"BlastAttackRelease";
}

namespace SubTagIslandSecurityMech
{
	const FName Dodge = n"Dodge";
}

struct FIslandSecurityMechFeatureTags
{
	UPROPERTY()
	FName Locomotion = FeatureTagIslandSecurityMech::Locomotion;
	
	UPROPERTY()
	FName JumpUp = FeatureTagIslandSecurityMech::JumpUp;

	UPROPERTY()
	FName JumpDown = FeatureTagIslandSecurityMech::JumpDown;
	
	UPROPERTY()
	FName Land = FeatureTagIslandSecurityMech::Land;


	UPROPERTY()
	FName LaserStart = FeatureTagIslandSecurityMech::LaserStart;

	UPROPERTY()
	FName LaserEnd = FeatureTagIslandSecurityMech::LaserEnd;

	
	UPROPERTY()
	FName LaserShot = FeatureTagIslandSecurityMech::LaserShot;
	
	UPROPERTY()
	FName BullitShot = FeatureTagIslandSecurityMech::BullitShot;
	
	UPROPERTY()
	FName RocketShot = FeatureTagIslandSecurityMech::RocketShot;

	UPROPERTY()
	FName AimingRocket = FeatureTagIslandSecurityMech::AimingRocket;

	UPROPERTY()
	FName GunPose = FeatureTagIslandSecurityMech::GunPose;

	UPROPERTY()
	FName SwingAttack = FeatureTagIslandSecurityMech::SwingAttack;

	UPROPERTY()
	FName HitReaction = FeatureTagIslandSecurityMech::HitReaction;
	
	UPROPERTY()
	FName SmallHitReaction = FeatureTagIslandSecurityMech::SmallHitReaction;

	UPROPERTY()
	FName LaunchRocket = FeatureTagIslandSecurityMech::LaunchRocket;

	
	UPROPERTY()
	FName Stunned = FeatureTagIslandSecurityMech::Stunned;

	UPROPERTY()
	FName Death = FeatureTagIslandSecurityMech::Death;

	UPROPERTY()
	FName StartFlyDeath = FeatureTagIslandSecurityMech::StartFlyDeath;

	UPROPERTY()
	FName FlyDeath = FeatureTagIslandSecurityMech::FlyDeath;

	UPROPERTY()
	FName Reload = FeatureTagIslandSecurityMech::Reload;

	UPROPERTY()
	FName AirAttack = FeatureTagIslandSecurityMech::AirAttack;

	UPROPERTY()
	FName BlastAttackCharge = FeatureTagIslandSecurityMech::BlastAttackCharge;
	
	UPROPERTY()
	FName BlastAttackRelease = FeatureTagIslandSecurityMech::BlastAttackRelease;
}




class UAnimInstanceSecurityMech : UAnimInstanceAIBase
{
	// Animations

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData FlyingMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Fly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData WalkStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Walk;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Dodge;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData WalkStop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData TurnLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData TurnRigth;
    
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData AimSpace;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData LemonAimSpace;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData AvoidLandLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData AvoidLandRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData JumpForward;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData JumpUpwards;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData JumpLand;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
    FHazePlayRndSequenceData  StartFlyingDeath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
    FHazePlayRndSequenceData FlyingDeath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Combat")
    FHazePlaySequenceData LaserStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Combat")
    FHazePlaySequenceData LaserEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Combat")
   	FHazePlayBlendSpaceData Laser;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Combat")
    FHazePlaySequenceData Bullit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Combat")
    FHazePlaySequenceData GunPose;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Combat")
   	bool bPlayAdditiveShooting;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData SwingAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|HitReaction")
   	bool bPlayAdditiveHitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|SmallHitReaction")
   	bool bPlayAdditiveSmallHitReaction;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|HitReaction")
    FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|SmallHitReaction")
    FHazePlaySequenceData SmallHitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaunchRocket")
    FHazePlaySequenceData LaunchRocket;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData Stunned;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlayRndSequenceData Death;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData BlastAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData BlastAttackLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData BlastAttackRelease;



	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaunchRocket")
   	FHazePlaySequenceData AirAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaunchRocket")
    FHazePlaySequenceData Reload;






	


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Cached data")
	bool bIsFlying = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Cached data")
	bool bIsJumping = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Cached data")
	bool bIsDodging = false;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Cached data")
	bool bIsChargingBlastAttack = false;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bAimingLaser;
	
	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsAimingRocket;


	UPROPERTY()	
	bool bShootThisTick;

	UPROPERTY()	
	bool bHitThisTick;

	UIslandJetpackShieldotronComponent JetpackComp;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandSecurityMechFeatureTags FeatureTags;


	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();
	
		if(HazeOwningActor != nullptr)
		{
			JetpackComp = UIslandJetpackShieldotronComponent::Get(HazeOwningActor);
		}
	}	
	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
	
		if (JetpackComp != nullptr)
			bIsFlying = JetpackComp.GetCurrentFlyState() != EIslandJetpackShieldotronFlyState::IsGrounded;
		
		bIsChargingBlastAttack = (CurrentFeatureTag == FeatureTagIslandSecurityMech::BlastAttackCharge);
		
		bIsDodging = (CurrentSubTag == SubTagIslandSecurityMech::Dodge);

		bShootThisTick =  (CurrentFeatureTag == FeatureTagIslandSecurityMech::RocketShot) || (CurrentFeatureTag == FeatureTagIslandSecurityMech::BullitShot);
		if (bShootThisTick)
			bPlayAdditiveShooting = true;

		bAimingLaser = (CurrentFeatureTag == FeatureTagIslandSecurityMech::LaserShot);

		bIsAimingRocket = (CurrentFeatureTag == FeatureTagIslandSecurityMech::AimingRocket);
	
		bHitThisTick =  (CurrentFeatureTag == FeatureTagIslandSecurityMech::HitReaction);
		if (bHitThisTick)
			bPlayAdditiveHitReaction = true;

		bHitThisTick =  (CurrentFeatureTag == FeatureTagIslandSecurityMech::SmallHitReaction);
		if (bHitThisTick)
			bPlayAdditiveSmallHitReaction = true;

	
	
}

	UFUNCTION()
	void AnimNotify_StoppedShooting() 
	{
	bPlayAdditiveShooting = false;
	}	

	UFUNCTION()
	void AnimNotify_StoppedHitReaction() 
	{
	bPlayAdditiveHitReaction  = false;
	}	

		UFUNCTION()
	void AnimNotify_StoppedSmallHitReaction() 
	{
	bPlayAdditiveSmallHitReaction  = false;
	}	
	
	}	
