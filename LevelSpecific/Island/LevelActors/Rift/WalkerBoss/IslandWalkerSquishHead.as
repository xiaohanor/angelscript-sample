event void FIslandWalkerSquishHeadSignature();

class AIslandWalkerSquishHead : AHazeActor
{
	UPROPERTY()
	FIslandWalkerSquishHeadSignature OnHeadHit;
	
	UPROPERTY()
	FIslandWalkerSquishHeadSignature OnHeadFlattened;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "BaseComp")
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	UAnimSequence Idle;

	UPROPERTY()
	FVector HeadScaleOne = FVector(1, 1, 1);
	UPROPERTY()
	FVector HeadScaleTwo = FVector(1, 1, 0.8);
	UPROPERTY()
	FVector HeadScaleThree = FVector(1, 1, 0.5);
	UPROPERTY()
	FVector HeadScaleFour = FVector(1, 1, 0.1);

	FVector CurrentScale = FVector(1, 1, 1);
	FVector DestinationScale = FVector(1, 1, 0.8);

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 0.1;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	int CurrentSmashNumber;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0);
		PlayIdleAnimation();
	}

	UFUNCTION()
	void SquishHead(int SquishValue)
	{
		CurrentSmashNumber = SquishValue;

		if (SquishValue == 1)
		{
			CurrentScale = FVector(HeadScaleOne); 
			DestinationScale = FVector(HeadScaleTwo); 

		}

		if (SquishValue == 2)
		{
			CurrentScale = FVector(HeadScaleTwo); 
			DestinationScale = FVector(HeadScaleThree);
			StopAnimation();

		}

		if (SquishValue == 3)
		{
			CurrentScale = FVector(HeadScaleThree); 
			DestinationScale = FVector(HeadScaleFour);

		}


		MoveAnimation.PlayFromStart();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		BaseComp.SetRelativeScale3D(Math::Lerp(CurrentScale, DestinationScale, Alpha));

	}

	UFUNCTION()
	void OnFinished()
	{
		if (CurrentSmashNumber == 3)
			OnHeadFlattened.Broadcast();
		else
			OnHeadHit.Broadcast();
	}

	UFUNCTION()
	void PlayIdleAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Idle;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	UFUNCTION()
	void StopAnimation()
	{
		FHazeStopSlotAnimationParams Params;
		Params.BlendTime = 0.5;
		SkelMesh.StopSlotAnimation(Params);
	}

}

UCLASS(Abstract)
class UIslandWalkerSquishHeadEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestination() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingMusicRef() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestinationMusicRef() {}
}