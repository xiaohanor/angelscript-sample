
class UAnimInstanceCoastWingSuit : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData BarrelRoll;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData GrappleTrain;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Throw;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Pull;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData WingsFolded;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FlyingOffRamp;

	

	// FeatureTags and SubTags

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int BarrelRollDirection;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrapplingToPoint; 

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrapplingToTrain; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWingsuitMovementActive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFromCutscene;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWingsuitIsLandingOnGround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFlyingOffRamp;

	UPlayerMovementComponent MoveComponent;
	UWingSuitPlayerComponent WingSuitComp;

	AWingSuit WingSuit;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		
		
	}

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		WingSuit = Cast<AWingSuit>(HazeOwningActor);
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (WingSuit == nullptr)
			return;

		if(WingSuit.PlayerOwner == nullptr)
			return;

		if(MoveComponent == nullptr || WingSuitComp == nullptr)
		{
			MoveComponent =  UPlayerMovementComponent::Get(WingSuit.PlayerOwner);
			WingSuitComp = UWingSuitPlayerComponent::Get(WingSuit.PlayerOwner);
		}

		const FVector MovementInputActorSpace = MoveComponent.SyncedMovementInputForAnimationOnly;

		float TargetY = 0;

		// Version 1
		//TargetY = -Math::Clamp((WingSuitComp.SyncedInternalRotation.Value.Pitch / 45) / 1.2 + -MovementInputActorSpace.Z, -1.0, 1.0);
		
		// Version 2
		float Pitch = Math::UnwindDegrees(WingSuitComp.SyncedInternalRotation.Value.Pitch);
		TargetY = -Math::Min((Pitch / 45), MovementInputActorSpace.Z);

		

		float BlendspaceInterpSpeedY = BlendspaceValues.Y < TargetY ? 7 : 3; 
		BlendspaceValues.Y = Math::FInterpTo(BlendspaceValues.Y, TargetY, DeltaTime, BlendspaceInterpSpeedY);	
		if (BarrelRollDirection == 0)
		{
			
			BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, MovementInputActorSpace.Y, DeltaTime, 1.5);	
		}
		else 
		{
			BlendspaceValues.X = BarrelRollDirection;
		}		
		
		
		BarrelRollDirection = WingSuitComp.AnimData.ActiveBarrelRollDirection;
		bGrapplingToPoint = WingSuitComp.AnimData.bIsGrappling;
		bGrapplingToTrain = WingSuitComp.AnimData.bIsTransitioningToWaterski;
		bWingsuitMovementActive = WingSuitComp.bWingsuitActive;
		bFromCutscene = WingSuitComp.bActivatedFromCutscene;
		bWingsuitIsLandingOnGround = WingSuitComp.AnimData.bIsLandingOnGround;  
		bIsFlyingOffRamp = WingSuitComp.AnimData.bIsFlyingOffRamp;
        
    }
}