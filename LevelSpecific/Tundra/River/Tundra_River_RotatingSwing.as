class ATundra_River_RotatingSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingScene;

	UPROPERTY(DefaultComponent, Attach = MovingScene)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USwingPointComponent SwingPointComp;

	TArray<AHazePlayerCharacter> PlayersUsingGrapple;

	UPROPERTY()
	FHazeTimeLike SwingAnimation;	
	default SwingAnimation.Duration = 1;
	default SwingAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default SwingAnimation.Curve.AddDefaultKey(1, 1.0);

	UPROPERTY(EditInstanceOnly)
	float RotationAngle = -90;

	UPROPERTY(EditInstanceOnly)
	float SwingTime = 2;

	float ReverseTimer = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"OnPlayerAttachToGrapple");
		SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"OnPlayerDetachFromGrapple");
		SwingAnimation.BindUpdate(this, n"TL_SwingAnimationUpdate");
		SwingAnimation.BindFinished(this, n"TL_SwingAnimationFinished");
		SwingAnimation.PlayRate = 1/SwingTime;
	}

	UFUNCTION()
	void OnPlayerAttachToGrapple(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		PlayersUsingGrapple.AddUnique(Player);
		UTundra_River_RotatingSwing_EffectHandler::Trigger_AttachToGrapple(this);
		TryPlayAnimation();
	}

	UFUNCTION()
	void OnPlayerDetachFromGrapple(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		PlayersUsingGrapple.Remove(Player);
		UTundra_River_RotatingSwing_EffectHandler::Trigger_DetachFromGrapple(this);
		ReverseTimer = 2;	
	}

	UFUNCTION()
	void TL_SwingAnimationUpdate(float CurveValue)
	{
		MovingScene.SetRelativeRotation(FRotator(0, CurveValue*RotationAngle, 0));
	}

	UFUNCTION()
	void TL_SwingAnimationFinished()
	{
		UTundra_River_RotatingSwing_EffectHandler::Trigger_StopMoving(this);
		ReverseTimer = 2;
	}

	void TryPlayAnimation()
	{
		if((!SwingAnimation.IsPlaying() || SwingAnimation.IsReversed()) && SwingAnimation.GetPosition() < 1)
		{
			UTundra_River_RotatingSwing_EffectHandler::Trigger_StartMoving(this);
			SwingAnimation.Play();
		}
	}

	void TryToReverse()
	{
		if(PlayersUsingGrapple.Num() <= 0 && !SwingAnimation.IsPlaying() && ReverseTimer <= SMALL_NUMBER && SwingAnimation.GetPosition() > 0)
		{
			UTundra_River_RotatingSwing_EffectHandler::Trigger_StartMovingBackToStart(this);
			SwingAnimation.Reverse();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ReverseTimer > 0)
		{
			ReverseTimer -= DeltaSeconds;
			if(ReverseTimer <= 0)
			{
				TryToReverse();
			}
		} 
	}
};