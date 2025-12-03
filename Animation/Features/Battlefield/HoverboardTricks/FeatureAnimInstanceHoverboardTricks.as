UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardTricks : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardTricks Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardTricksAnimData AnimData;

	UPlayerMovementComponent MoveComponent;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UBattlefieldHoverboardFreeFallingComponent SkydiveComp;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAboutToSkydive;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComponent =  UPlayerMovementComponent::Get(Player);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
		SkydiveComp = UBattlefieldHoverboardFreeFallingComponent::GetOrCreate(Player);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardTricks NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardTricks);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		Banking = GetAnimFloatParam(n"HoverboardBanking", true);

		AdditiveBankingAlpha = 0;

		SlopeAlignComp.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);

		bAboutToSkydive = SkydiveComp.bShouldFreeFall;


	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.12; 
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BankingValues.X = MoveComponent.SyncedMovementInputForAnimationOnly.Y;

		if (AdditiveBankingAlpha < 1)
			AdditiveBankingAlpha += DeltaTime / 3.2;
			

		
		Banking = Math::FInterpTo(Banking, BankingValues.X, DeltaTime, 0.9);

		SlopeRotation = Math::RInterpTo(SlopeRotation, FRotator::ZeroRotator, DeltaTime, 3.0);
		SlopeOffset = Math::VInterpTo(SlopeOffset, FVector::ZeroVector, DeltaTime, 3.0);

		

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"HoverboardSkydiving")
			return LowestLevelGraphRelevantAnimTimeRemaining < 0.55;

		if (LocomotionAnimationTag != n"HoverboardAirMovement")
			return true;

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardLanding")
			SetAnimFloatParam(n"HoverboardBanking", Banking);
	}
}
