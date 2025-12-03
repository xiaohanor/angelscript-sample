class UAnimInstanceTundraThornSpider : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Turn;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotationTurn;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurn;

	AEvergreenPoleCrawler Crawler;

	FVector CachedActorLocation;

	bool bCrawlingUp;
	bool bFirstFrame;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
			Crawler = Cast<AEvergreenPoleCrawler>(HazeOwningActor);

		bFirstFrame = true;
		CachedActorLocation = HazeOwningActor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Crawler == nullptr)
			return;

		FVector Velocity = FVector::ZeroVector;
		if (DeltaTime > 0)
		{
			Velocity = (HazeOwningActor.ActorLocation - CachedActorLocation) / DeltaTime;
			BlendspaceValues.Y = (Velocity.Size() / OwningComponent.WorldScale.X);
		}
		else
			BlendspaceValues.Y = 0;

		CachedActorLocation = HazeOwningActor.ActorLocation;

		if (Crawler.bIsInEvergreenSide)
		{
			bTurn = CheckValueChangedAndSetBool(bCrawlingUp, Velocity.Z > 0);

			if (bFirstFrame)
			{
				if (Math::Abs(Velocity.Z) > SMALL_NUMBER)
					bFirstFrame = false;
				bTurn = false;
			}
			else if (bCrawlingUp)
			{
				HipsRotationTurn = FRotator(0, 180, 0);
				HipsRotation = FRotator::ZeroRotator;
			}
			else
			{
				HipsRotationTurn = FRotator::ZeroRotator;
				HipsRotation = FRotator(0, 180, 0);
			}
		}
	}
}