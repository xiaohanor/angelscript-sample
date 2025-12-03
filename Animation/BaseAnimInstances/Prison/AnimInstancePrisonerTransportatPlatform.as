class UAnimInstancePrisonerTransportatPlatform : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Reaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ReactedMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReaction = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipReactionEnter = false;

	APrisonerTransportPlatform TransformPlatform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LookAtTarget;

	AHazeActor LookAtTargetActor;
	float UpdateLookAtTargetTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
			TransformPlatform = Cast<APrisonerTransportPlatform>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (TransformPlatform == nullptr)
			return;

		bSkipReactionEnter = TransformPlatform.bLandingReactionEnabled;
		bReaction = TransformPlatform.bLandingReactionTriggered;

		if (bReaction)
		{
			UpdateLookAtTargetTimer -= DeltaTime;
			if (UpdateLookAtTargetTimer < 0)
			{
				UpdateLookAtTargetActor();
				UpdateLookAtTargetTimer = 5;
			}

			if (LookAtTargetActor != nullptr)
				LookAtTarget = LookAtTargetActor.ActorLocation;
		}
	}

	UFUNCTION()
	void UpdateLookAtTargetActor()
	{
		if (OwningComponent.WorldLocation.DistSquared(Game::Mio.ActorLocation) < OwningComponent.WorldLocation.DistSquared(Game::Zoe.ActorLocation))
			LookAtTargetActor = Game::Mio;
		else
			LookAtTargetActor = Game::Zoe;
	}
}