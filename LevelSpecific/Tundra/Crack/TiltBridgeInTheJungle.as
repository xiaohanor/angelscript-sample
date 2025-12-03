event void FTiltBridgeInTheJungleGroundSlamEvent(bool bVineIsBlocking);

class ATiltBridgeInTheJungle : ASnowMonkeyCatapult
{
	UPROPERTY(EditAnywhere)
	float StayDownDuration = 2.0;

	/* Min angle when the vine is not blocking */
	UPROPERTY(EditAnywhere)
	float UnblockedMinConstraint = 0.0;

	/* Max angle when the vine is not blocking */
	UPROPERTY(EditAnywhere)
	float UnblockedMaxConstraint = 15.0;

	/* Min angle when the catapult is below vine */
	UPROPERTY(EditAnywhere)
	float BlockedBelowMinConstraint = 13.0;

	/* Max angle when the catapult is above vine */
	UPROPERTY(EditAnywhere)
	float BlockedAboveMaxConstraint = 10.0;

	UPROPERTY()
	FTiltBridgeInTheJungleGroundSlamEvent OnBridgeGroundSlammed;

	bool bVineIsBlocking = false;
	AHazePlayerCharacter MonkeyPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		FauxAxisRotator.OnMaxConstraintHit.AddUFunction(this, n"HitBottom");
		MonkeyPlayer = Game::Mio;
	}

	UFUNCTION()
	private void HitBottom(float Strength)
	{
		FauxAxisRotator.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if(!bApplyImpulses && FauxWeight.IsEnabled() && Math::IsNearlyEqual(FauxAxisRotator.CurrentRotation, Math::DegreesToRadians(UnblockedMinConstraint)))
		{
			bApplyImpulses = true;
		}
	}

	

	void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation) override
	{
		Super::OnGroundSlam(GroundSlamType, PlayerLocation);

		if(!bApplyImpulses)
			return;
		
		FauxWeight.AddDisabler(this);
		NetOnBridgeGroundSlammed(bVineIsBlocking);
		bApplyImpulses = false;
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	private void NetOnBridgeGroundSlammed(bool bVineBlocking)
	{
		OnBridgeGroundSlammed.Broadcast(bVineBlocking);

		if(MonkeyPlayer.OtherPlayer.HasControl())
			Timer::SetTimer(this, n"ResetWeight", StayDownDuration);
	}

	UFUNCTION(NotBlueprintCallable)
	private void ResetWeight()
	{
		NetResetWeight();
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	private void NetResetWeight()
	{
		FauxWeight.RemoveDisabler(this);
	}

	UFUNCTION(BlueprintCallable)
	void SetVineIsBlocking()
	{
		if(bVineIsBlocking)
			return;

		bVineIsBlocking = true;

		if(IsBelow())
			FauxAxisRotator.ConstrainAngleMin = BlockedBelowMinConstraint;
		else
			FauxAxisRotator.ConstrainAngleMax = BlockedAboveMaxConstraint;
	}

	UFUNCTION(BlueprintCallable)
	void SetVineIsNotBlocking()
	{
		if(!bVineIsBlocking)
			return;

		bVineIsBlocking = false;

		FauxAxisRotator.ConstrainAngleMin = UnblockedMinConstraint;
		FauxAxisRotator.ConstrainAngleMax = UnblockedMaxConstraint;
	}

	bool IsBelow()
	{
		return Math::RadiansToDegrees(FauxAxisRotator.CurrentRotation) > BlockedAboveMaxConstraint;
	}
}