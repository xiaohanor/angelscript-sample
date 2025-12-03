namespace FeatureTagIslandPunchotron
{
	const FName Locomotion = n"Locomotion";

	
	const FName JumpAttack = n"JumpAttack";

	const FName HaywireAttack = n"HaywireAttack";

	const FName CloseSwingLeft = n"CloseSwingLeft";

	const FName CloseSwingRight = n"CloseSwingRight";

	const FName SpinAttack = n"SpinAttack";

	const FName SpinComboAttack = n"SpinComboAttack";

	const FName BackhandAttack = n"BackhandAttack";

	const FName KickAttack = n"KickAttack";

	const FName Stunned = n"Stunned";

	const FName Death = n"Death";

	const FName JumpStart = n"JumpStart";

	const FName FallStart = n"FallStart";

	const FName FallLoop = n"FallLoop";

	const FName AttackCooldown = n"AttackCooldown";

	const FName WheelchairKick = n"WheelchairKick";

	const FName WheelchairFire = n"WheelchairFire";

	const FName CobraStrike = n"CobraStrike";

	const FName HelicopterLoop = n"HelicopterLoop";

	const FName ChopLoop = n"ChopLoop";


}

struct FIslandPunchotronFeatureTags
{
	UPROPERTY()
	FName Locomotion = FeatureTagIslandPunchotron::Locomotion;

	
	UPROPERTY()
	FName JumpAttack = FeatureTagIslandPunchotron::JumpAttack;

	UPROPERTY()
	FName HaywireAttack = FeatureTagIslandPunchotron::HaywireAttack;

	UPROPERTY()
	FName CloseSwingLeft = FeatureTagIslandPunchotron::CloseSwingLeft;
	
	UPROPERTY()
	FName CloseSwingRight = FeatureTagIslandPunchotron::CloseSwingRight;

	UPROPERTY()
	FName SpinAttack = FeatureTagIslandPunchotron::SpinAttack;

	UPROPERTY()
	FName SpinComboAttack = FeatureTagIslandPunchotron::SpinComboAttack;

	UPROPERTY()
	FName BackhandAttack = FeatureTagIslandPunchotron::BackhandAttack;

	UPROPERTY()
	FName KickAttack = FeatureTagIslandPunchotron::KickAttack;

	UPROPERTY()
	FName Stunned = FeatureTagIslandPunchotron::Stunned;

	UPROPERTY()
	FName Death = FeatureTagIslandPunchotron::Death;

	UPROPERTY()
	FName JumpStart = FeatureTagIslandPunchotron::JumpStart;

	UPROPERTY()
	FName FallStart = FeatureTagIslandPunchotron::FallStart;

	UPROPERTY()
	FName FallLoop = FeatureTagIslandPunchotron::FallLoop;

	UPROPERTY()
	FName AttackCooldown = FeatureTagIslandPunchotron::AttackCooldown;
	
	UPROPERTY()	
	FName WheelchairKick = FeatureTagIslandPunchotron::WheelchairKick;

	UPROPERTY()
	FName WheelchairFire = FeatureTagIslandPunchotron::WheelchairFire;
	
	UPROPERTY()
	FName CobraStrike = FeatureTagIslandPunchotron::CobraStrike;

	
	UPROPERTY()
	FName HelicopterLoop = FeatureTagIslandPunchotron::HelicopterLoop;

	UPROPERTY()
	FName ChopLoop = FeatureTagIslandPunchotron::ChopLoop;


}




class UAnimInstanceIslandPunchotron : UAnimInstanceAIBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData WalkBS;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Mh;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData WalkStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Walk;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData WalkStop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData TurnLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData TurnRight;
    
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData AimSpace;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData FallStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData FallLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData FallLanding;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData JumpStart;



	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData JumpAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData HaywireAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData CloseSwingLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData CloseSwingRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData SpinAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData SpinComboAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData BackhandAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData KickAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData Stunned;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData Death;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData AttackCooldown;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData WheelchairKickStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData WheelchairKickLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData WheelchairKickEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData WheelchairFireStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData WheelchairFireLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData WheelchairFireEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData CobraStrike;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData HelicopterStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData HelicopterLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData HelicopterEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData ChopStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData ChopLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeCombat")
    FHazePlaySequenceData ChopEnd;


	
	UPROPERTY(Transient, NotEditable, BlueprintReadOnly, Category = "Cached data")
	float TakeDamageReactionAlpha = 0.0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandPunchotronFeatureTags FeatureTags;


	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();
	
	}	
	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		// Temp
		if (bHurtReactionThisTick)
			TakeDamageReactionAlpha += DeltaTime;
		else
			TakeDamageReactionAlpha -= DeltaTime;
		TakeDamageReactionAlpha = Math::Clamp(TakeDamageReactionAlpha, 0.0, 0.05);
	}
	
}	
