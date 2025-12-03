class ADentistBounceBubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BubbleRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShape;
	
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY()
	FHazeTimeLike GrowTimeLike;

	UPROPERTY()
	FHazeTimeLike ShrinkTimeLike;

	UPROPERTY()
	float SmallScale = 2.0;

	UPROPERTY()
	float BigScale = 12.0;
	
	UPROPERTY()
	float ImpulseStrength = 1000.0;

	UPROPERTY(EditAnywhere)
	FDentistToothApplyRagdollSettings RagdollSettings;

	UPROPERTY(EditAnywhere)
	float StartDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float BigWaitDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float SmallWaitDuration = 4.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrowTimeLike.BindUpdate(this, n"GrowTimeLikeUpdate");
		GrowTimeLike.BindFinished(this, n"GrowTimeLikeFinished");
		ShrinkTimeLike.BindUpdate(this, n"ShrinkTimeLikeUpdate");
		ShrinkTimeLike.BindFinished(this, n"ShrinkTimeLikeFinished");

		MovementImpactCallbackComponent.OnAnyImpactByPlayer.AddUFunction(this, n"HandlePlayerImpact");

		if (StartDelay == 0.0)
			GrowTimeLike.PlayFromStart();
		else
			Timer::SetTimer(this, n"PlayGrowTimeLike", StartDelay);
	}

	UFUNCTION()
	private void PlayGrowTimeLike()
	{
		GrowTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void GrowTimeLikeUpdate(float CurrentValue)
	{
		BubbleRoot.SetRelativeScale3D(FVector(Math::Lerp(SmallScale, BigScale, CurrentValue)));
	}

	UFUNCTION()
	private void GrowTimeLikeFinished()
	{
		Timer::SetTimer(this, n"PlayShrinkTimeLike", BigWaitDuration);
	}

	UFUNCTION()
	private void PlayShrinkTimeLike()
	{
		ShrinkTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void ShrinkTimeLikeUpdate(float CurrentValue)
	{
		BubbleRoot.SetRelativeScale3D(FVector(Math::Lerp(BigScale, SmallScale, CurrentValue)));
	}

	UFUNCTION()
	private void ShrinkTimeLikeFinished()
	{
		Timer::SetTimer(this, n"PlayGrowTimeLike", SmallWaitDuration);
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		if (GrowTimeLike.IsPlaying())
		{
			FVector ImpulseDirection = (Player.ActorLocation - ActorLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector);
			FVector Impulse = ImpulseDirection * ImpulseStrength;

			if (Impulse.Z < 500.0)
				Impulse.Z = 500.0;

			auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
			if(ResponseComp != nullptr)
			{
				ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);
			}
		}
	}
};