namespace FeatureTagStinger
{
	const FName Flying = n"Flying";
	const FName RapidFire = n"RapidFire";
	const FName Dodge = n"Dodge";
	const FName Charge = n"Charge";
}

struct FStingerFeatureTags
{
	UPROPERTY()
	FName Flying = FeatureTagStinger::Flying;
	UPROPERTY()
	FName RapidFire = FeatureTagStinger::RapidFire;
	UPROPERTY()
	FName Dodge = FeatureTagStinger::Dodge;
	UPROPERTY()
	FName Charge = FeatureTagStinger::Charge;
}

namespace SubTagStinger
{
	const FName Idle = n"Idle";
	const FName Shoot = n"Shoot";
}

struct FStingerSubTags
{
	UPROPERTY()
	FName Idle = SubTagStinger::Idle;
	UPROPERTY()
	FName Shoot = SubTagStinger::Shoot;
}

namespace SubTagStingerRapidFire
{
	const FName RapidFireStart = n"RapidFireStart";
	const FName RapidFire = n"RapidFire";
	const FName RapidFireEnd = n"RapidFireEnd";
}

struct FStingerRapidFireSubTags
{
	UPROPERTY()
	FName RapidFireStart = SubTagStingerRapidFire::RapidFireStart;
	UPROPERTY()
	FName RapidFire = SubTagStingerRapidFire::RapidFire;
	UPROPERTY()
	FName RapidFireEnd = SubTagStingerRapidFire::RapidFireEnd;
}

namespace SubTagStingerDodge
{
	const FName Left = n"Left";
	const FName Right = n"Right";
}

struct FStingerDodgeSubTags
{
	UPROPERTY()
	FName Left = SubTagStingerDodge::Left;
	UPROPERTY()
	FName Right = SubTagStingerDodge::Right;
}

namespace SubTagStingerCharge
{
	const FName ChargeTelegraph = n"ChargeTelegraph";
	const FName ChargeStart = n"ChargeStart";
	const FName Charge = n"Charge";
	const FName ChargeEnd = n"ChargeEnd";
	const FName ChargeStuck = n"ChargeStuck";
}

struct FStingerChargeSubTags
{
	UPROPERTY()
	FName ChargeTelegraph = SubTagStingerCharge::ChargeTelegraph;
	UPROPERTY()
	FName ChargeStart = SubTagStingerCharge::ChargeStart;
	UPROPERTY()
	FName Charge = SubTagStingerCharge::Charge;
	UPROPERTY()
	FName ChargeEnd = SubTagStingerCharge::ChargeEnd;
	UPROPERTY()
	FName ChargeStuck = SubTagStingerCharge::ChargeStuck;
}

UCLASS(Abstract)
class UFeatureAnimInstanceStinger : UAnimInstanceAIBase
{
    UPROPERTY(Category = "StingerAnimation")
	FHazePlayRndSequenceData FlyingMH;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData DodgeLeft;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData DodgeRight;

    UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ShootMH;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlayBlendSpaceData Shoot;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlayBlendSpaceData RapidFireEnter;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlayBlendSpaceData RapidFireShoot;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeTelegraphMH;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeEnter;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeMH;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeExit;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeStuckEnter;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeStuckMH;

	UPROPERTY(Category = "StingerAnimation")
	FHazePlaySequenceData ChargeStuckExit;





	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FStingerFeatureTags FeatureTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FStingerSubTags SubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FStingerDodgeSubTags DodgeSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FStingerRapidFireSubTags RapidFireSubTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FStingerChargeSubTags ChargeSubTags;

	UPROPERTY(BlueprintReadOnly)
	float ShootAngle;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		if(HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void LogAnimationTemporalData(FTemporalLog& TemporalLog) const
	{
		Super::LogAnimationTemporalData(TemporalLog);
	}
}
