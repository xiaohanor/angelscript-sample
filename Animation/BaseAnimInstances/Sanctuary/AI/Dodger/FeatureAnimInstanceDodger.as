namespace FeatureTagDodger
{
	const FName Default = n"Flying";
	const FName Sleeping = n"Sleep";
	const FName DarkPortal = n"DarkPortal";
}

struct FDodgerFeatureTags
{
	UPROPERTY()
	FName Default = FeatureTagDodger::Default;
	UPROPERTY()
	FName Sleeping = FeatureTagDodger::Sleeping;
	UPROPERTY()
	FName DarkPortal = FeatureTagDodger::DarkPortal;
}

namespace SubTagDodgerSleeping
{
	const FName SleepHanging = n"SleepHanging";
	const FName SleepStanding = n"SleepStanding";
	const FName WakeUp = n"WakeUp";
	const FName Shrug = n"Shrug";
}

struct FDodgerSleepingSubTags
{
	UPROPERTY()
	FName SleepHangingName = SubTagDodgerSleeping::SleepHanging;
	UPROPERTY()
	FName SleepStandingName = SubTagDodgerSleeping::SleepStanding;
	UPROPERTY()
	FName WakeUpName = SubTagDodgerSleeping::WakeUp;
	UPROPERTY()
	FName ShrugName = SubTagDodgerSleeping::Shrug;
}

namespace SubTagDodger
{
	const FName Landing = n"Landing";
	const FName Mh = n"Mh";
	const FName Shoot = n"Shoot";
	const FName StartFly = n"StartFly";
	const FName Fly = n"Fly";
	const FName Dodge = n"Dodge";
	const FName ChargeFly = n"ChargeFly";
	const FName ChargeTelegraph = n"ChargeTelegraph";
	const FName DarkPortal = n"DarkPortal";
}

struct FDodgerSubTags
{
	UPROPERTY()
	FName LandingName = SubTagDodger::Landing;
	UPROPERTY()
	FName MhName = SubTagDodger::Mh;
	UPROPERTY()
	FName ShootName = SubTagDodger::Shoot;
	UPROPERTY()
	FName StartFlyName = SubTagDodger::StartFly;
	UPROPERTY()
	FName FlyName = SubTagDodger::Fly;
	UPROPERTY()
	FName DodgeName = SubTagDodger::Dodge;
	UPROPERTY()
	FName ChargeFly = SubTagDodger::ChargeFly;
	UPROPERTY()
	FName ChargeTelegraph = SubTagDodger::ChargeTelegraph;

	UPROPERTY()
	FName DarkPortal = SubTagDodger::DarkPortal;
}

UCLASS(Abstract)
class UFeatureAnimInstanceDodger : UAnimInstanceAIBase
{
	//UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	//UDodgerComponent DodgerComponent;

    UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData FlyingMH;

	UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData StartFly;

	UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData Fly;

	UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData Landing;

    UPROPERTY(Category = "DodgerAnimation|Attack")
	FHazePlaySequenceData ShootMH;

	UPROPERTY(Category = "DodgerAnimation|Attack")
	FHazePlayBlendSpaceData Shoot;

	UPROPERTY(Category = "DodgerAnimation|Attack")
	FHazePlaySequenceData LandingShoot;

	UPROPERTY(Category = "DodgerAnimation|Sleep")
	FHazePlaySequenceData SleepingHanging;

	UPROPERTY(Category = "DodgerAnimation|Sleep")
	FHazePlaySequenceData ShrugHanging;

	UPROPERTY(Category = "DodgerAnimation|Sleep")
	FHazePlaySequenceData WakeUpHanging;

	UPROPERTY(Category = "DodgerAnimation|Sleep")
	FHazePlaySequenceData SleepingStanding;

	UPROPERTY(Category = "DodgerAnimation|Sleep")
	FHazePlaySequenceData ShrugStanding;

	UPROPERTY(Category = "DodgerAnimation|Sleep")
	FHazePlaySequenceData WakeUpStanding;

	UPROPERTY(Category = "DodgerAnimation|Dodge")
	FHazePlaySequenceData DodgeLeft;

	UPROPERTY(Category = "DodgerAnimation|Dodge")
	FHazePlaySequenceData DodgeRight;

	UPROPERTY(Category = "DodgerAnimation|MhGround")
	FHazePlaySequenceData MhGround;

	UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData FlyingTelegraph;

	UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData FlyingCharge;

	UPROPERTY(Category = "DodgerAnimation|Movement")
	FHazePlaySequenceData DarkPortal;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FDodgerFeatureTags FeatureTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FDodgerSubTags SubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FDodgerSleepingSubTags SleepingSubTags;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
	}
}