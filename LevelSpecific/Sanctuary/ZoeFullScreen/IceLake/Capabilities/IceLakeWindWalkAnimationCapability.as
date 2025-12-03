class UIceLakeWindWalkAnimationCapability : UHazePlayerCapability
{
    UWindWalkComponent PlayerComp;
	UWindWalkDataComponent DataComp;
    UWindDirectionResponseComponent ResponseComp;
	UHazeMovementComponent MoveComp;

	FHazeAcceleratedFloat AccStruggle;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindWalkComponent::GetOrCreate(Player);
		DataComp = UWindWalkDataComponent::Get(Player);
        ResponseComp = UWindDirectionResponseComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(!PlayerComp.GetIsStrongWind())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(!PlayerComp.GetIsStrongWind())
            return true;

        return false;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccStruggle.Value = MoveComp.MovementInput.Size();
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FVector WindDirection = ResponseComp.WindDirection;

		FVector TargetDirection = MoveComp.MovementInput;
		float InputSize = MoveComp.MovementInput.Size();

		// If we have input, use the input forward. Otherwise use the actor forward
		FVector ActorForward = InputSize > KINDA_SMALL_NUMBER ? TargetDirection : Player.ActorForwardVector;

		// How much are we aligned with wind forward?
		float ForwardAlignment = -WindDirection.DotProduct(ActorForward);
		PlayerComp.AnimationData.ForwardFactor = ForwardAlignment;

		// How much are we aligned with wind right?
		FVector RightVector = ActorForward.CrossProduct(FVector::UpVector).GetSafeNormal();
		float RightAlignment = -WindDirection.DotProduct(RightVector);
		PlayerComp.AnimationData.RightFactor = RightAlignment;
		
		// How much are we struggling? (trying to move against the wind)
		float Duration = DataComp.Settings.StruggleAccelerationDuration;
		if(ForwardAlignment > KINDA_SMALL_NUMBER)
			AccStruggle.AccelerateTo(InputSize, Duration, DeltaTime);
		else
			AccStruggle.AccelerateTo(Math::Saturate(MoveComp.HorizontalVelocity.Size() * DataComp.Settings.StruggleMoveSpeedMultiplier), Duration, DeltaTime);
		
		PlayerComp.AnimationData.PlayRate = Math::Lerp(DataComp.Settings.NoStrugglePlayRate, 1.0, AccStruggle.Value);

		// Anim values
		PlayerComp.AnimationData.HorizontalVelocity = MoveComp.HorizontalVelocity;
		PlayerComp.AnimationData.MovementInput = MoveComp.MovementInput;
		PlayerComp.AnimationData.WindDirection = WindDirection;
		PlayerComp.AnimationData.Speed = MoveComp.HorizontalVelocity.Size();
    }
}