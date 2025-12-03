UCLASS(Abstract)
class UFeatureAnimInstanceWaterski : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWaterski Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWaterskiAnimData AnimData;

	// Add Custom Variables Here
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerMovementComponent MoveComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRopeVisible;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTransitioningToWingsuit;

	// FHazeAcceleratedFloat

	UCoastWaterskiPlayerComponent WaterskiComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D OverideBlendspaceValues;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MoveComponent =  UPlayerMovementComponent::Get(Player);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWaterski NewFeature = GetFeatureAsClass(ULocomotionFeatureWaterski);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		
		if (Feature == nullptr)
			return;

		const FVector MovementInputActorSpace = Player.GetActorRotation().UnrotateVector(MoveComponent.SyncedMovementInputForAnimationOnly);
		BlendspaceValues.X = MovementInputActorSpace.Y;

	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.8;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const FVector MovementInputActorSpace = MoveComponent.GetSyncedLocalSpaceMovementInputForAnimationOnly();
		BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, MovementInputActorSpace.Y, DeltaTime, 5.5);
		BlendspaceValues.Y = Math::FInterpTo(BlendspaceValues.Y, Math::Clamp(-MoveComponent.VerticalSpeed / 500, -1.0, 1.0), DeltaTime, 7);

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.6);

		FVector AttachDir = (WaterskiComp.CurrentWaterskiAttachPoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
		AttachDir = Player.ActorRotation.UnrotateVector(AttachDir);
		OverideBlendspaceValues.X = AttachDir.Y;

		bRopeVisible = !WaterskiComp.IsWaterskiRopeBlocked();
		bTransitioningToWingsuit = WaterskiComp.AnimData.bTransitioningToWingsuit;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
