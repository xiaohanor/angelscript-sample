
struct FLocomotionFeatureGrappleFishAnimData
{
	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData Swim;

	UPROPERTY(Category = "SandFish")
	FHazePlayBlendSpaceData TurnBS;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData Dive;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData DiveSmall;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData Breach;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData MioEndJump;

	UPROPERTY(Category = "SandFish")
	FHazePlaySequenceData ZoeEndJump;
}

UCLASS(Abstract)
class UFeatureAnimInstanceGrappleFish : UHazeAnimInstanceBase
{
	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGrappleFishAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ADesertGrappleFish GrappleFish;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AnimData")
	float ForwardSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AnimData")
	FDesertGrappleFishAnimData GrappleFishAnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		GrappleFish = Cast<ADesertGrappleFish>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (GrappleFish == nullptr)
			return;

		ForwardSpeed = HazeOwningActor.ActorVelocity.DotProduct(HazeOwningActor.ActorForwardVector);
		GrappleFishAnimData = GrappleFish.AnimData;
	}
}
