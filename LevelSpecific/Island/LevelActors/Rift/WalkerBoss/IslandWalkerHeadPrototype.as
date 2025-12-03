event void FAIslandWalkerHeadPrototypeSignature();

class AIslandWalkerHeadPrototype : AHazeActor
{
	
	UPROPERTY()
	FAIslandWalkerHeadPrototypeSignature OnImpact;
	UPROPERTY()
	FAIslandWalkerHeadPrototypeSignature OnActivated;
	UPROPERTY()
	FAIslandWalkerHeadPrototypeSignature OnDead;
	UPROPERTY()
	FAIslandWalkerHeadPrototypeSignature OnReachedDestination;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InteractionMesh;

	UPROPERTY(DefaultComponent, Attach = InteractionMesh)
	UIslandRedBlueImpactCounterResponseComponent RedBlueComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType BlockColor;

	UPROPERTY(EditAnywhere)
	bool bStartDeactivated;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	UAnimSequence Idle;
	UPROPERTY()
	UAnimSequence RoarAnim;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 30.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	float CurrentAlpha;
	AHazePlayerCharacter LastPlayerImpacter;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RedBlueComponent.OnImpactEvent.AddUFunction(this, n"ShieldImpact");
		RedBlueComponent.OnFullAlpha.AddUFunction(this, n"ShieldDeactived");

		if (bStartDeactivated)
			BP_DeactivateHead();

		if(SplineActor == nullptr)
			return;

		Spline = SplineActor.Spline;
		// OnUpdate(0.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
	}

	UFUNCTION()
	void ActivateSplineMove()
	{
		PlayRoarAnimation();
		MoveAnimation.PlayFromStart();
	}


	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		
		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);

	}

	UFUNCTION()
	void OnFinished()
	{
		PlayIdleAnimation();
		OnReachedDestination.Broadcast();
	}

	UFUNCTION()
	void ShieldImpact(FIslandRedBlueImpactResponseParams Data)
	{
		LastPlayerImpacter = Data.Player;
		OnImpact.Broadcast();
	}

	UFUNCTION()
	private void ShieldDeactived(AHazePlayerCharacter Player)
	{
		OnActivated.Broadcast();
	}

	UFUNCTION()
	void ActivateHead(bool bActivateHealthBar = true)
	{
		PlayIdleAnimation();
		BP_ActivateHead(bActivateHealthBar);
	}

	UFUNCTION()
	void WalkerHeadDead()
	{
		OnDead.Broadcast();
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
	void PlayRoarAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = RoarAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = false;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}


	UFUNCTION(BlueprintEvent)
	void BP_DeactivateHead() {}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateHead(bool bActivateHealthBar = true) {}

}