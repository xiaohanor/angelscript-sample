UCLASS(Abstract)
class UFeatureAnimInstanceGravityBikeWhip : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBikeWhip Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBikeWhipAnimData AnimData;

	// Add Custom Variables Here

	UGravityBikeWhipComponent WhipComp;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FGravityBikeSplineAnimationData BikeAnimData;
	UGravityBikeSplinePlayerComponent PlayerComp;
	AGravityBikeSpline GravityBike;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHolstered;

	// FGravityBikeWhipAnimationData
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bHasGravityWhip;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsWhipping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EGravityBikeWhipState WhipState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsBashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipInputDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipReboundDirection;

	// In screen space, what direction is the item we want to grab in?
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipTargetGrabDirection;

	// In screen space, what direction is the main target we will throw a grabbed item at?
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipTargetReleaseDirection;	
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrabbedObjectLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasTarget;

	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityBikeWhip NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBikeWhip);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here


		WhipComp = UGravityBikeWhipComponent::Get(Player);
		bHasGravityWhip = WhipComp != nullptr;
		PlayerComp = UGravityBikeSplinePlayerComponent::Get(Player);
		GravityBike = PlayerComp.GravityBike;
		
		
		UpdateWhipAnimData();
		
		if (WhipTargetGrabDirection.X < 0.0)
			bIsGrabbedObjectLeft = true;
		else
			bIsGrabbedObjectLeft = false;

		if (WhipState == EGravityBikeWhipState::StartGrab)
			WhipReboundDirection.X = Math::RoundToInt(WhipTargetGrabDirection.X);

		CopyAnimBoneTransforms(n"RightAttach", n"RightHand_IK", bCopyTranslation = false);

		WhipComp.bIsHolstered = false;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bIsHolstered = WhipComp.bIsHolstered;

		UpdateWhipAnimData();

		WhipComp.WhipActor.SetAnimBoolParam(n"BikeWhipGrabbedObjectLeft", bIsGrabbedObjectLeft);
		
		WhipComp.WhipActor.SetAnimVector2DParam(n"BikeWhipReboundDirection", WhipReboundDirection);

		WhipComp.WhipActor.SetAnimVector2DParam(n"BikeWhipTargetReleaseirection", WhipTargetReleaseDirection);
		
		//WhipComp.WhipActor.SetAnimFloatParam(n"ThrowStartPosition", ThrowStartPosition);

		BikeAnimData = GravityBike.AnimationData;
		Speed = BikeAnimData.Speed;

		// if (WhipState == EGravityBikeWhipState::ThrowRebound)
		// {
		// 	if (WhipTargetReleaseDirection.X > 0.0)
		// 	{
		// 		WhipReboundDirection.X = 1.0;
		// 	}
		// 	else if (WhipTargetReleaseDirection.X < 0.0)
		// 	{	
		// 		WhipReboundDirection.X = -1.0;
		// 	}
		// 	else 
		// 	{
		// 		WhipReboundDirection.X = WhipInputDirection.X; 
		// 	}
		// }
		// else if (WhipState == EGravityBikeWhipState::Throw)	
		// {
		// 	WhipReboundDirection.Y = WhipInputDirection.Y;
		// 	WhipReboundDirection.X = WhipInputDirection.X * 4.0;
		// }

	

#if EDITOR
	/*
		PrintToScreen(f"{WhipState=}");
	Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"RightHand_IK"), Game::Zoe.Mesh.GetSocketRotation(n"RightHand_IK"), 50, 3);
		PrintToScreen(f"{WhipReboundDirection=}");
		PrintToScreen(f"{WhipTargetReleaseDirection=}");
		PrintToScreen(f"{WhipTargetGrabDirection=}");
		PrintToScreen(f"{WhipInputDirection=}");
		PrintToScreenScaled(f"{bHasTarget=}", 0, FLinearColor::LucBlue, 3);
	*/
#endif	

	}

	private void UpdateWhipAnimData()
	{
		if(!bHasGravityWhip)
			return;

		bIsWhipping = WhipComp.GetWhipState() != EGravityBikeWhipState::None;
		WhipState = WhipComp.GetWhipState();
		WhipInputDirection = WhipComp.GetInputDirection();

		WhipTargetGrabDirection = WhipComp.GetMainGrabTargetDirection();
		bHasTarget = WhipComp.HasThrowTarget();

		if(bHasTarget)
			WhipTargetReleaseDirection = WhipComp.GetPlayerToThrowTargetVectorUV();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName == n"Release" && TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1)
			return true;

		if (WhipState == EGravityBikeWhipState::None && TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		WhipComp.bIsHolstered = true;
	}
}

class UGravityBikeWhipHolsteredAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
	            FAnimNotifyEventReference EventReference) const
	{
		auto GravWhipComp = UGravityBikeWhipComponent::Get(MeshComp.Owner);
		if (GravWhipComp != nullptr)
			GravWhipComp.bIsHolstered = true;

		return true;
	}
}
