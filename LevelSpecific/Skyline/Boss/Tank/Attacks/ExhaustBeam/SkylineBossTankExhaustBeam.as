class ASkylineBossTankExhaustBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float Length = 15000.0; // 5000
	float Width = 500.0;

	bool bActivated = false;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.5;

	TPerPlayer<bool> bInFrontLastFrame;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ActivationAnimation;
	default ActivationAnimation.Duration = 1.0;
	default ActivationAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ActivationAnimation.Curve.AddDefaultKey(1.0, 1.0);
	default ActivationAnimation.bCurveUseNormalizedTime = true;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DeactivationAnimation;
	default DeactivationAnimation.Duration = 1.0;
	default DeactivationAnimation.Curve.AddDefaultKey(0.0, 1.0);
	default DeactivationAnimation.Curve.AddDefaultKey(1.0, 0.0);
	default DeactivationAnimation.bCurveUseNormalizedTime = true;


	UPROPERTY(BlueprintReadOnly)
	float Alpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationAnimation.BindUpdate(this, n"ActivationAnimationUpdate");
		ActivationAnimation.BindFinished(this, n"ActivationAnimationFinished");
		DeactivationAnimation.BindUpdate(this, n"DeactivationAnimationUpdate");
		DeactivationAnimation.BindFinished(this, n"DeactivationAnimationFinished");
	
	}

	void Activate(float ActivationTime)
	{
		ActivationAnimation.SetPlayRate(1.0 / ActivationTime);
		ActivationAnimation.Play();
	}

	void Deactivate(float DectivationTime)
	{
		DeactivationAnimation.SetPlayRate(1.0 / DectivationTime);
		DeactivationAnimation.Play();
	}

	UFUNCTION()
	private void ActivationAnimationUpdate(float CurrentValue)
	{
		Alpha = CurrentValue;
	}

	UFUNCTION()
	private void ActivationAnimationFinished()
	{
		bActivated = true;
	}

	UFUNCTION()
	private void DeactivationAnimationUpdate(float CurrentValue)
	{
		Alpha = CurrentValue;
	}

	UFUNCTION()
	private void DeactivationAnimationFinished()
	{
		bActivated = false;
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Start = ActorLocation;
		FVector End = Start + ActorForwardVector * Length;

		Debug::DrawDebugLine(Start, End, FLinearColor::Green, 100.0, 0.0);

		for (auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			
			FVector RelativeLocationToBeam = ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			bool bIsBehind = RelativeLocationToBeam.X > 0.0 && RelativeLocationToBeam.Y < 0.0;

			if (IsContinuouslyGrounded(Player))
			{
				if ((bInFrontLastFrame[Player] && bIsBehind && RelativeLocationToBeam.X < Length))
					Player.DamagePlayerHealth(Damage);
			}

			bInFrontLastFrame[Player] = RelativeLocationToBeam.X > 0.0 && RelativeLocationToBeam.Y > 0.0;
		}
	}

	bool IsContinuouslyGrounded(AHazePlayerCharacter Player)
	{
		auto MoveComp = GravityBikeFree::GetGravityBike(Player).MoveComp;
		return MoveComp.PreviousHadGroundContact() && MoveComp.HasGroundContact();
	}
};