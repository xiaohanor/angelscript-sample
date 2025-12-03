UCLASS(Abstract)
class UFeatureAnimInstanceOgreMovement : UHazeAnimInstanceBase
{

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FLocomotionFeatureOgreMovementAnimData AnimData;

	AVillageOgreBase Ogre;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRunning;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBreakWall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Velocity;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Ogre = Cast<AVillageOgreBase>(HazeOwningActor);
		AnimData = Ogre.AnimFeature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Ogre == nullptr)
			return;
		
		bIsRunning = Ogre.bFollowingSpline;
		bBreakWall = Ogre.bBreakingWall;
		bJumping = Ogre.bJumping;
		Velocity = Ogre.MoveSpeed;
	}
}
