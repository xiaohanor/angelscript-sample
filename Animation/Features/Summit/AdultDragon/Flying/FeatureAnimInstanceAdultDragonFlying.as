UCLASS(Abstract)
class UFeatureAnimInstanceAdultDragonFlying : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAdultDragonFlying Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAdultDragonFlyingAnimData AnimData;

	UPlayerAdultDragonComponent DragonComp;
	UPlayerAcidAdultDragonComponent AcidComp;
	UPlayerTailAdultDragonComponent TailComp;

	AAdultDragon AdultDragon;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EAdultDragonAnimationState CurrentState;

	// Logic for transitioning from AirSmash

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

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator AimRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartDashing;

	// Pitch logic

	FRotator CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PitchInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DeltaPitch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Pitch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float NormalizedPitch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PreviousDeltaPitch;

	FHazeAcceleratedFloat UpperBodyPitchSpring;

	FHazeAcceleratedFloat LowerBodyPitchSpring;

	FHazeAcceleratedFloat TailPitchSpring;

	// Additive banking logic

	// Swimming

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSwimming;

	// TODO: Rename this to DeltaYaw
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DeltaRoll;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BankInput;

	float PreviousDeltaRoll; // TODO: Rename this to PreviousDeltaYaw

	FHazeAcceleratedFloat UpperBodyRollSpring;

	FHazeAcceleratedFloat LowerBodyRollSpring;

	FHazeAcceleratedFloat LegsRollSpring;

	FHazeAcceleratedFloat TailRollSpring;

	// Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;

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

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DivePitch;

	float DeltaDivePitch;

	float PreviousPitch;

	float DiveTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartDiving;

	float PitchSpringMultiplier;

	float PitchSpringMultiplierInterpSpeed;

	// Flap Logic
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "WingFlaps")
	int FlapsNeeded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGapFlying;

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
		if (AdultDragon == nullptr)
			AdultDragon = Cast<AAdultDragon>(HazeOwningActor.AttachParentActor);

		DragonComp = AdultDragon.DragonComponent;
		AcidComp = UPlayerAcidAdultDragonComponent::Get(Game::Mio);
		TailComp = UPlayerTailAdultDragonComponent::Get(Game::Zoe);

		// How much each flap type deducts from the `FlapScore`
		FlapTypeIntensity.Reset();
		FlapTypeIntensity.Add(0, 10);
		FlapTypeIntensity.Add(1, 20);
		FlapTypeIntensity.Add(2, 30);

		bIsAcid = AdultDragon.IsAcidDragon();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAdultDragonFlying NewFeature = GetFeatureAsClass(ULocomotionFeatureAdultDragonFlying);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (PrevLocomotionAnimationTag == n"AdultDragonAirSmash")
		{
			AirSmashRollAlpha = 1;
			AdditiveAlpha = 0.2;
			AirSmashRollDirection = GetAnimFloatParam(n"DragonAirSmashRollDirectionFloat", bConsume = true, DefaultValue = 0);

			AirSmashRollDamping = GetAnimFloatParam(n"DragonAirSmashDampingFloat", true, 0) / 2;

			AirSmashRollTarget = GetAnimFloatParam(n"DragonAirSmashRollFloatTarget", true, 0);
		}
		else
		{
			AirSmashRollAlpha = 0;
			AirSmashRollDirection = 0;
			AirSmashRollDamping = 0;
			AirSmashRollTarget = 0;
			ClearAnimFloatParam(n"DragonAirSmashRollDirectionFloat");
			ClearAnimFloatParam(n"DragonAirSmashDampingFloat");
			ClearAnimFloatParam(n"DragonAirSmashRollFloatTarget");
		}

		// AirSmashRollDirection = GetAnimFloatParam (n"DragonAirSmashRollDirectionFloat", bConsume = true, DefaultValue = 0);

		// AirSmashRollDamping = GetAnimFloatParam (n"DragonAirSmashDampingFloat", true, 0)/2;

		// AirSmashRollTarget = GetAnimFloatParam (n"DragonAirSmashRollFloatTarget", true, 0);

		PitchSpringMultiplierInterpSpeed = 1;

		PitchSpringMultiplier = 1;

		// Start a timer that checks every x seconds if we should play flap anims
		FlapCheckTimer = Timer::SetTimer(this, n"CheckFlapScore", 0.6, true);

		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(AdultDragon);
		PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.2);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == "AdultDragonAirSmash" && CurrentState == EAdultDragonAnimationState::Flying)
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

		CurrentState = DragonComp.AnimationState.Get();

		Pitch = DragonComp.AnimParams.SplineRelativeDragonRotation.Pitch;

		NormalizedPitch = DragonComp.AnimParams.SplineRelativeDragonRotation.Pitch / 75;

		bStartDashing = DragonComp.AnimParams.bDashInitialized;

		// AirSmashRoll stuff

		DragonComp.AnimParams.AnimAirSmashRoll.SpringTo(AirSmashRollTarget, 15, AirSmashRollDamping, DeltaTime);

		AirSmashRollValue = DragonComp.AnimParams.AnimAirSmashRoll.Value;

		if (CurrentState == EAdultDragonAnimationState::Hover)
		{
			AdditiveAlpha = Math::FInterpTo(AdditiveAlpha, 0.2, DeltaTime, 1);
		}
		else
		{
			AdditiveAlpha = Math::FInterpTo(AdditiveAlpha, 1, DeltaTime, 1);
		}

		FRotator DeltaRotation = (DragonComp.AnimParams.SplineRelativeDragonRotation - CachedActorRotation).Normalized;

		CachedActorRotation = DragonComp.AnimParams.SplineRelativeDragonRotation;

		// Calculating how input affects the target value for the additive banking/pitching

		PitchInput = DragonComp.AnimParams.Pitching;

		if (Math::Abs(PitchInput) > SMALL_NUMBER)
		{
			if (!Math::IsNearlyZero(DeltaTime))
				DeltaPitch = Math::Clamp((Math::FInterpTo(DeltaPitch, DeltaRotation.Pitch / DeltaTime / 68, DeltaTime, 8)), -1, 1);
		}
		else
		{
			DeltaPitch = Math::Clamp((Math::FInterpTo(DeltaPitch, 0, DeltaTime, 2)), -1, 1);
		}

		BankInput = DragonComp.AnimParams.Banking;

		if (Math::Abs(BankInput) > SMALL_NUMBER)
		{
			if (!Math::IsNearlyZero(DeltaTime))
				DeltaRoll = Math::Clamp((Math::FInterpTo(DeltaRoll, DeltaRotation.Yaw / DeltaTime / 60, DeltaTime, 8)), -1, 1);
		}
		else
		{
			DeltaRoll = Math::Clamp((Math::FInterpTo(DeltaRoll, 0, DeltaTime, 8)), -1, 1);
		}

		// Additive Pitching

		DivePitch = Math::FInterpTo(DivePitch, (NormalizedPitch - PreviousPitch) * 10, DeltaTime, 0);

		PreviousDeltaPitch = DeltaPitch;

		PreviousPitch = NormalizedPitch;

		UpperBodyAdditiveValues.Y = DeltaPitch;

		PitchSpringMultiplierInterpSpeed = Math::FInterpTo(PitchSpringMultiplierInterpSpeed, 1, DeltaTime, 1);

		PitchSpringMultiplier = Math::FInterpTo(PitchSpringMultiplier, 1, DeltaTime, PitchSpringMultiplierInterpSpeed);

		if (bStartDiving)
		{
			LowerBodyPitchSpring.SpringTo(DeltaPitch * -1, 10 * PitchSpringMultiplier, 0.3, DeltaTime);
		}
		else
		{
			LowerBodyPitchSpring.SpringTo(DeltaPitch, 10 * PitchSpringMultiplier, 0.3, DeltaTime);
		}

		LowerBodyAdditiveValues.Y = LowerBodyPitchSpring.Value;

		TailPitchSpring.SpringTo(LowerBodyAdditiveValues.Y, 20 * PitchSpringMultiplier, 0.2, DeltaTime);

		TailAdditiveValues.Y = TailPitchSpring.Value;

		// Diving logic and how it affects AdditiveValues.Y (pitching up/down) interpolation

		bStartDiving = false;

		float DiveTimerMultiplier = 0;

		if (Pitch > 20)
		{
			DiveTimerMultiplier = 1;
		}
		else
		{
			DiveTimer = Math::FInterpTo(DiveTimer, 0, DeltaTime, 2);
		}

		DiveTimer += DeltaTime * DiveTimerMultiplier + ((DeltaPitch - PreviousDeltaPitch) / 68);

		if (DiveTimer > 2 && DivePitch < -0.2 && Pitch < 40)
		{
			bStartDiving = true;
			DiveTimer = 0;
			PitchSpringMultiplier = 10;
			PitchSpringMultiplierInterpSpeed = 0.1;
			FlapScore -= 75;
			FlapsNeeded = 0;
		}

		// Additive Banking

		if (bIsSwimming)
		{
			UpperBodyRollSpring.SpringTo(DeltaRoll, 5, 0.6, DeltaTime);

			LowerBodyRollSpring.SpringTo(DeltaRoll, 2, 0.5, DeltaTime);

			LegsRollSpring.SpringTo(LowerBodyAdditiveValues.X, 10, 0.7, DeltaTime);

			TailRollSpring.SpringTo(LowerBodyAdditiveValues.X, 7, 0.4, DeltaTime);

			FlapScore = 70;
		}
		else
		{
			UpperBodyRollSpring.SpringTo(DeltaRoll, 15, 0.5, DeltaTime);

			LowerBodyRollSpring.SpringTo(DeltaRoll, 10, 0.3, DeltaTime);

			LegsRollSpring.SpringTo(LowerBodyAdditiveValues.X, 30, 0.5, DeltaTime);

			TailRollSpring.SpringTo(LowerBodyAdditiveValues.X, 20, 0.2, DeltaTime);
		}

		UpperBodyAdditiveValues.X = UpperBodyRollSpring.Value;

		LowerBodyAdditiveValues.X = LowerBodyRollSpring.Value;

		LegsAdditiveValues.X = LegsRollSpring.Value;

		TailAdditiveValues.X = TailRollSpring.Value;

		// Wingflap logic
		if (CurrentState == EAdultDragonAnimationState::Flying)
			CalculateFlapScore(DeltaTime);

		// TailLookAtLocation = Game::GetZoe().GetViewTransform().TransformPosition(FVector(20000, 0, 620));
		TailLookAtLocation = TailComp.AimOrigin + TailComp.AimDirection * 20000;

		AcidLookAtLocation = AcidComp.AimOrigin + AcidComp.AimDirection * 20000;

		// Debug::DrawDebugSphere(AcidLookAtLocation, LineColor = FLinearColor::Red);

		// Debug::DrawDebugSphere(TailLookAtLocation, LineColor = FLinearColor::Green);

		bIsSwimming = DragonComp.AnimParams.bIsSwimming;

		// bIsGapFlying is currently used to force gliding animation when flying sideways through gaps
		bIsGapFlying = DragonComp.bGapFlying;
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
			if (FlapScore < FlapHeavyThreshold)
			{
				const int Odds = FlapScore < FlapMediumThreshold ? 75 : 40;
				if (RandomBoolByOdds(Odds))
					return;
			}

			int NumberOfFlapsToRequest = Math::RandRange(0, 3);
			FlapsNeeded = Math::Clamp(FlapsNeeded + NumberOfFlapsToRequest, 0, 3);
		}
		if (Pitch < -45)
		{
			FlapsNeeded = 0;
			FlapScore -= 20;
		}
	}

	void CalculateFlapScore(float DeltaTime)
	{
		// float Multiplier = (1 + Math::Exp2(Pitch / 10)) * Math::Clamp(Pitch, -1.0, 1.0);
		float Multiplier = 5 + Pitch / 3;

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

		PhysAnimComp.ClearProfileAsset(this);
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
