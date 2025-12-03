UCLASS(Abstract)
class UFeatureAnimInstanceAdultDragonStrafe : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAdultDragonStrafe Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAdultDragonStrafeAnimData AnimData;

	UPlayerAdultDragonComponent DragonComp;
	UPlayerAcidAdultDragonComponent AcidComp;
	UAdultDragonStrafeComponent StrafeComp;

	AAdultDragon AdultDragon;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EAdultDragonStormStrafeState CurrentState;

	//Logic for transitioning from AirSmash

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AirSmash")
	float AirSmashRollValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AirSmash")
	float AirSmashRollDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "AirSmash")
	float AirSmashRollAlpha;

	float AirSmashRollTarget;

	float AirSmashRollDamping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAcid;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector AcidLookAtLocation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector TailLookAtLocation;		






	// Pitch logic

	FRotator CachedActorRotation;

	float PitchInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DeltaPitch;

	float Pitch;

	float NormalizedPitch;

	float PreviousDeltaPitch;

	FHazeAcceleratedFloat UpperBodyPitchSpring;

	FHazeAcceleratedFloat LowerBodyPitchSpring;

	FHazeAcceleratedFloat TailPitchSpring;

	// Additive banking logic

	// TODO: Rename this to DeltaYaw
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DeltaRoll;

	float BankInput;

	float PreviousDeltaRoll; // TODO: Rename this to PreviousDeltaYaw

	FHazeAcceleratedFloat UpperBodyRollSpring;

	FHazeAcceleratedFloat LowerBodyRollSpring;

	FHazeAcceleratedFloat LegsRollSpring;

	FHazeAcceleratedFloat TailRollSpring;


	// Additive Values set by Pitch and Bank logic

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D LowerBodyAdditiveValues;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D UpperBodyAdditiveValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D TailAdditiveValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D LegsAdditiveValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	float AdditiveAlpha;


	// Dive logic

	float DivePitch;

	float DeltaDivePitch;

	float PreviousPitch;

	float DiveTimer;

	float PitchSpringMultiplier;

	float PitchSpringMultiplierInterpSpeed;	

	// Flap Logic
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "WingFlaps")
	int FlapsNeeded;

	float FlapScore;
	int FlapIntensity;

	const float FlapLightThreshold = 15;
	const float FlapMediumThreshold = 20;
	const float FlapHeavyThreshold = 30;

	TMap<int, float> FlapTypeIntensity;
	FTimerHandle FlapCheckTimer;

#if TEST
	const bool bPrintDebugValues = false;
#endif



	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		AdultDragon = Cast<AAdultDragon>(HazeOwningActor);
		if(AdultDragon == nullptr)
			AdultDragon = Cast<AAdultDragon>(HazeOwningActor.AttachParentActor);

		DragonComp = AdultDragon.DragonComponent;
		AcidComp = Cast<UPlayerAcidAdultDragonComponent>(DragonComp);
		StrafeComp = UAdultDragonStrafeComponent::Get(DragonComp.Owner);

		// How much each flap type deducts from the `FlapScore`
		FlapTypeIntensity.Reset();
		FlapTypeIntensity.Add(0, 10);
		FlapTypeIntensity.Add(1, 25);
		FlapTypeIntensity.Add(2, 40);
		
		bIsAcid = AdultDragon.IsAcidDragon();
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAdultDragonStrafe NewFeature = GetFeatureAsClass(ULocomotionFeatureAdultDragonStrafe);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
		
		
		//AdditiveAlpha = 1;
		if (PrevLocomotionAnimationTag == n"AdultDragonAirSmash")
		{
			AdditiveAlpha = 0.2;
			AirSmashRollAlpha = 1;
		}
		else
		{
			AirSmashRollAlpha = 0;
			//AdditiveAlpha = 1;
		}
	
		AirSmashRollDirection = GetAnimFloatParam (n"DragonAirSmashRollDirectionFloat", bConsume = true, DefaultValue = 0);
		
		AirSmashRollDamping = GetAnimFloatParam (n"DragonAirSmashDampingFloat", true, 0)/2;

		AirSmashRollTarget = GetAnimFloatParam (n"DragonAirSmashRollFloatTarget", true, 0);

		PitchSpringMultiplierInterpSpeed = 1;

		PitchSpringMultiplier = 1;

		// Start a timer that checks every x seconds if we should play flap anims
		FlapCheckTimer = Timer::SetTimer(this, n"CheckFlapScore", 0.3, true);

		
	}


	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
		if (PrevLocomotionAnimationTag == "AdultDragonAirSmash" && CurrentState == EAdultDragonStormStrafeState::Flying)
		{
			return 1;
		}
		else
		{
        	return 0.2;
		}
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (DragonComp == nullptr)
			return;

		CurrentState = StrafeComp.AnimationState.Get();

		Pitch = AdultDragon.ActorRotation.Pitch;

		NormalizedPitch = AdultDragon.ActorRotation.Pitch / 75;

		//AirSmashRoll stuff

		DragonComp.AnimParams.AnimAirSmashRoll.SpringTo(AirSmashRollTarget, 15, AirSmashRollDamping, DeltaTime);

		AirSmashRollValue = StrafeComp.AnimAirSmashRoll.Value;

		FVector LocalVelocity = HazeOwningActor.GetActorLocalVelocity();

		AdditiveAlpha = Math::FInterpTo(AdditiveAlpha, 1, DeltaTime, 1);

		



		//Calculating how input affects the target value for the additive banking/pitching

		PitchInput = StrafeComp.Input.Y;
	

		if (Math::Abs(PitchInput) > SMALL_NUMBER)
		{
			DeltaPitch = Math::Clamp((Math::FInterpTo(DeltaPitch, LocalVelocity.Z / 3000, DeltaTime, 8)), -1,1);
		}
		else
		{
			DeltaPitch = Math::Clamp((Math::FInterpTo(DeltaPitch, 0, DeltaTime, 10)), -1,1);
		}

		BankInput = DragonComp.AnimParams.Banking;

		if (Math::Abs(StrafeComp.Input.X) > SMALL_NUMBER)
		{
			DeltaRoll = Math::Clamp((Math::FInterpTo(DeltaRoll, StrafeComp.Input.X, DeltaTime, 8)), -1, 1);
		}
		else
		{
			DeltaRoll = Math::Clamp((Math::FInterpTo(DeltaRoll, 0, DeltaTime, 15)), -1, 1);
		}

		
		
	
		
		// Additive Pitching

		
		PreviousDeltaPitch = DeltaPitch;

		PreviousPitch = NormalizedPitch;

		UpperBodyAdditiveValues.Y = DeltaPitch;

		PitchSpringMultiplierInterpSpeed = Math::FInterpTo(PitchSpringMultiplierInterpSpeed, 1, DeltaTime, 1);

		PitchSpringMultiplier = Math::FInterpTo(PitchSpringMultiplier, 1, DeltaTime, PitchSpringMultiplierInterpSpeed);


		LowerBodyPitchSpring.SpringTo(DeltaPitch, 10 * PitchSpringMultiplier, 0.3, DeltaTime);

		
		LowerBodyAdditiveValues.Y = LowerBodyPitchSpring.Value;

		

		TailPitchSpring.SpringTo(LowerBodyAdditiveValues.Y, 20 * PitchSpringMultiplier, 0.2, DeltaTime);

		TailAdditiveValues.Y = TailPitchSpring.Value;



		//Additive Banking

		UpperBodyRollSpring.SpringTo(DeltaRoll, 15, 0.5, DeltaTime * 2);

		LowerBodyRollSpring.SpringTo(DeltaRoll, 10, 0.3, DeltaTime * 1.5);

		LegsRollSpring.SpringTo(LowerBodyAdditiveValues.X, 30, 0.5, DeltaTime * 2);

		TailRollSpring.SpringTo(LowerBodyAdditiveValues.X, 20, 0.2, DeltaTime);

		UpperBodyAdditiveValues.X = UpperBodyRollSpring.Value;
		
		LowerBodyAdditiveValues.X = LowerBodyRollSpring.Value;

		LegsAdditiveValues.X = LegsRollSpring.Value;

		TailAdditiveValues.X = TailRollSpring.Value;

		// Wingflap logic
		if (CurrentState == EAdultDragonStormStrafeState::Flying)
			CalculateFlapScore(DeltaTime);


		
		TailLookAtLocation = Game::GetZoe().GetViewTransform().TransformPosition(FVector(5000, 0, 620));


		if(AcidComp != nullptr)
			AcidLookAtLocation = AcidComp.AimOrigin + AcidComp.AimDirection * 20000;
	
		

		Debug::DrawDebugSphere(AcidLookAtLocation, LineColor = FLinearColor::Green);
		
	
		

#if TEST
		PrintDebugValues();
#endif
	}


	/**
	 * Get a bool randomly selected based on the odds provided
	 * Example: with `RandomBool(10)` there's a 10% chance the function will return `true`;
	 */
	bool RandomBoolByOdds(int Odds = 50) const
	{
		return Math::RandRange(0, 100) < Odds;
	}


	/**
	 * 
	 */
	UFUNCTION()
	void CheckFlapScore()
	{
		if (FlapScore > FlapLightThreshold)
		{
			int NumberOfFlapsToRequest = Math::RandRange(0, 3);
			FlapsNeeded = Math::Clamp(FlapsNeeded + NumberOfFlapsToRequest, 0, 3);
		}
		if (Pitch < -45) {
			FlapsNeeded = 0;
			FlapScore -= 20;
		}
	}


	void CalculateFlapScore(float DeltaTime)
	{
		// float Multiplier = (1 + Math::Exp2(Pitch / 10)) * Math::Clamp(Pitch, -1.0, 1.0);
		float Multiplier = 1 + Pitch / 3;

		FlapScore += Math::Clamp(DeltaPitch, 0.0, 1.0);

		FlapScore += DeltaTime;
		FlapScore += Math::Abs(DeltaRoll) / 500;

		FlapScore += DeltaTime * Multiplier;

		// Clamp the score
		FlapScore = Math::Clamp(FlapScore, -10.0, 100.0);
	}


	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	int GetFlapIntensityLevel() const
	{
		if (FlapScore > FlapHeavyThreshold)
			return 2;
		else if (FlapScore > FlapMediumThreshold)
			return RandomBoolByOdds(10) ? 2 : 1;
		return RandomBoolByOdds(10) ? 1 : 0;
	}


	UFUNCTION()
    void AnimNotify_WingFlapStarted()
    {
		FlapsNeeded--;
		FlapScore -= (1 + FlapTypeIntensity[GetFlapIntensityLevel()]);
    }


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Stop the timer
		FlapCheckTimer.ClearTimerAndInvalidateHandle();
	}


#if TEST
	/** Function to print some debug values to screen */
	void PrintDebugValues()
	{
		if (!bPrintDebugValues)
			return;
		const FName DragonName = AdultDragon.Name.ToString().Contains("Tail") ? n"Tail" : n"Acid";

		// Keep in mind that prints added at the top of this function will be prited at the bottom of the screen.
		
		PrintToScreenScaled("GetFlapIntensityLevel: " + GetFlapIntensityLevel(), 0.f, Scale = 2.f, Color = FLinearColor::Teal);
		PrintToScreenScaled("FlapsNeeded: " + FlapsNeeded, 0.f, Scale = 2.f, Color = FLinearColor::Teal);
		PrintToScreenScaled("FlapScore: " + FlapScore, 0.f, Scale = 2.f, Color = FLinearColor::Teal);
		PrintToScreenScaled("=========== Flap Score =============", 0.f, Scale = 2.f, Color = FLinearColor::Teal);
		PrintToScreenScaled("*** " + DragonName + " ***", 0.f, Scale = 3.f, Color = FLinearColor::Blue);
	}
#endif

}
