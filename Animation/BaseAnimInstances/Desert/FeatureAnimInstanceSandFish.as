
struct FLocomotionFeatureSandFishAnimData
{
	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData Swim;

	UPROPERTY(Category = "SandFish")
	FHazePlayBlendSpaceData Turn;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData SmallDive;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData Dive;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData DiveAttack;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData DiveTurnLeft;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData DiveTurnRight;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData DiveSwim;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData AttackFromBelow;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData LungeAttack;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData RopeAttack;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData SwingMH;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData SwingAttackMH;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData SwingAttackBite;

}

UCLASS(Abstract)
class UFeatureAnimInstanceSandFish : UHazeAnimInstanceBase
{
	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSandFishAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeRuntimeSpline Spline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ASandShark SandShark;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AnimData")
	float ForwardSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AnimData")
	float ForwardBlendAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AnimData")
	FSandSharkAnimData SandSharkAnimData;

	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	USandSharkAnimationComponent AnimationComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		SandShark = Cast<ASandShark>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SandShark == nullptr)
			return;

		ForwardSpeed = HazeOwningActor.ActorVelocity.DotProduct(HazeOwningActor.ActorForwardVector);
		float TargetAlpha = Math::Abs(ForwardSpeed / 825.0) * 0.7;
		float NewAlpha = Math::FInterpConstantTo(ForwardBlendAlpha, TargetAlpha, DeltaTime, 0.5);
		ForwardBlendAlpha = NewAlpha;
		AnimationComp = USandSharkAnimationComponent::Get(HazeOwningActor);
		if (AnimationComp != nullptr)
		{
			SandSharkAnimData = AnimationComp.Data;
		}
	}
}
