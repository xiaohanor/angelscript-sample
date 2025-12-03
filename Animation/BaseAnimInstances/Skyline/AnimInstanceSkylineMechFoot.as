class UAnimInstanceSkylineMechFoot : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Move;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	ASkylineBoss SkylineBoss;

	ESkylineBossLeg Foot;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (SkylineBoss == nullptr)
		{
			if (HazeOwningActor != nullptr && HazeOwningActor.AttachParentActor != nullptr)
			{
				SkylineBoss = Cast<ASkylineBoss>(HazeOwningActor.AttachParentActor);

				const ASkylineBossLeg Leg = Cast<ASkylineBossLeg>(HazeOwningActor);
				Foot = Leg.GetLegIndex();
			}

			return;
		}

		bIsGrounded = SkylineBoss.LegComponents[Foot].bIsGrounded;
	}

	UFUNCTION()
	void AnimNotify_OnFootIdle()
	{
		OwningComponent.bNoSkeletonUpdate = true;
	}
}