class UAnimInstanceSketchBookPrinceCarry : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPlayerMovementComponent MovementComponent;

	AHazePlayerCharacter AttachedPlayer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (AttachedPlayer == nullptr)
		{
			if (HazeOwningActor != nullptr && HazeOwningActor.AttachParentActor != nullptr)
			{
				AttachedPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
				MovementComponent = UPlayerMovementComponent::Get(AttachedPlayer);
			}
			return;
		}

		const FVector LocalVelocity = AttachedPlayer.GetActorLocalVelocity();

		BlendspaceValues.Y = LocalVelocity.X;
		BlendspaceValues.X = MovementComponent.GetMovementYawVelocity(false) / 500;
	}
}