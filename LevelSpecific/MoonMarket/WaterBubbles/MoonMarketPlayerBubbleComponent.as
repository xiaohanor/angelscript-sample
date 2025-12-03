class UMoonMarketPlayerBubbleComponent : UActorComponent
{
	AMoonMarketWaterBubble CurrentBubble;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;
	

	UPROPERTY(EditDefaultsOnly)
	const float MoveIntoBubbleSpeed = 100;
	
	UPROPERTY(EditDefaultsOnly)
	const float PlayerVerticalOffsetInBubble = -50;


	//Used if there is no target bubble to use for trajectory
	UPROPERTY(EditDefaultsOnly)
	const float JumpOutVerticalImpulse = 1250;

	UPROPERTY(EditDefaultsOnly)
	const float JumpOutForwardImpulse = 800;

	UPROPERTY(EditDefaultsOnly)
	const float TrajectoryLaunchSpeed = 900;

	UPROPERTY(EditDefaultsOnly)
	const float SpringStiffness = 100;

	UPROPERTY(EditDefaultsOnly)
	const float SpringDamping = 0.4;

	UPROPERTY(EditDefaultsOnly)
	const FHazePlaySlotAnimationParams SwimAnimation;

	UPROPERTY(EditDefaultsOnly)
	const FHazePlaySlotAnimationParams LaunchAnimation;

	UMoonMarketShapeshiftComponent ShapeshiftComp;

	bool bCanJump = false;
	USceneComponent TargetedBubbleSceneComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShapeshiftComp = UMoonMarketShapeshiftComponent::GetOrCreate(Owner);
	}
};