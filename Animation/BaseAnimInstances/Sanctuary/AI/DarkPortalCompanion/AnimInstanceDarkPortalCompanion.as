namespace DarkPortalCompanionAnimTags
{
	const FName IntroStart = n"IntroStart";
	const FName IntroReachPlayer = n"IntroReachPlayer";
	const FName Follow = n"Follow";
	const FName LaunchStart = n"LaunchStart";
	const FName LaunchStartAttach = n"LaunchStartAttach";
	const FName Launch = n"Launch";
	const FName LaunchBlocked = n"LaunchBlocked";
	const FName LaunchAttached = n"LaunchAttached";
	const FName PortalExit = n"PortalExit";
	const FName Investigate = n"Investigate";
	const FName InvestigateAttached = n"InvestigateAttached";
	const FName TeleportToPlayer = n"TeleportToPlayer";
}

struct FLocomotionFeatureDarkPortalCompanionAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Intro")
	FHazePlaySequenceData IntroStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Intro")
	FHazePlaySequenceData IntroReachPlayer;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayRndSequenceData Gestures;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData UpperBodyAdditive;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData TwistAdditive;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData CurlAdditive;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData PitchYawAdditive;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData BendAdditive;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlayBlendSpaceData DashAdditive;
	UPROPERTY(Category = "Animations|Moray")
	FHazePlaySequenceData ChargeStart;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlaySequenceData ChargeMh;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlaySequenceData ThrowStart;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlaySequenceData PortalStart;

	UPROPERTY(Category = "Animations|Moray")
	FHazePlaySequenceData PortalMh;

}

enum EDarkPortalCompanionLocomotionState
{
	Follow,
	LaunchStart,
	Launching,
	LaunchAttached,
	PortalExit,
	TeleportToPlayer,
}

UCLASS(Abstract)
class UAnimInstanceDarkPortalCompanion : UAnimInstanceAIBase
{
	UPROPERTY(meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDarkPortalCompanionAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerSwimmingAnimData SwimmingAnimData;

	FRotator CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DeltaYaw;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D HeadAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D LowerBodyAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D UpperBodyAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D TailAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	float AdditiveBankingAlpha;

	bool bRotatingIntoTurn;

	FHazeAcceleratedFloat UpperBodyRollSpring;

	FHazeAcceleratedFloat LowerBodyRollSpring;

	FHazeAcceleratedFloat HeadRollSpring;

	FHazeAcceleratedFloat TailRollSpring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D HeadAdditivePitchValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D LowerBodyAdditivePitchValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D UpperBodyAdditivePitchValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D TailAdditivePitchValues;

	FHazeAcceleratedFloat HeadPitchSpring;

	FHazeAcceleratedFloat UpperBodyPitchSpring;

	FHazeAcceleratedFloat LowerBodyPitchSpring;

	FHazeAcceleratedFloat TailPitchSpring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFollowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIntroStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIntroReachPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchStartAttach;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchAttached;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchBlocked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPortalExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MovementSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LocomotionPlayRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurlAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TrailAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TwistAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DashSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DashPlayRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D QuickRotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float NoInputTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashingThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTeleportedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTeleportToPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EDarkPortalCompanionLocomotionState LocomotionState;

	bool bNotifiedTeleport;
	bool bPhysDisableTeleport = false;

	UPROPERTY(BlueprintReadOnly)
	UHazePhysicalAnimationProfile PhysProf;

	UHazePhysicalAnimationComponent PhysComp;

	FVector LocalVelocity;

	// Variables not exposed to the ABP
	// FTimerHandle PaddleTimerHandle;
	// float BreastStrokeTimer;
	// UBasicAIDestinationComponent DestinationComp;
	// FHazeAcceleratedFloat MovementScale;

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 5;
	const float HIP_PITCH_INTERPSPEED_STOP = 0.5;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4;			   // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3;			   // Interp speed for the lower body
	const float ADDITIVE_BANKING_LOWERBODY_BREASTSTROKE_INTERP_SPEED = 10; // Interp speed for the lower body during breast stroke
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5;					   // When going from Mh -> Swim, how fast should the banking activate

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		if (HazeOwningActor == nullptr)
			return;

		LocomotionState = EDarkPortalCompanionLocomotionState::Follow;
		UTeleportResponseComponent::GetOrCreate(HazeOwningActor).OnTeleported.AddUFunction(this, n"OnTeleported");

		PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		PhysComp.ApplyProfileAsset(this, PhysProf);
	}

	UFUNCTION()
	void OnTeleported()
	{
		bPhysDisableTeleport = true;
		bTeleportedThisFrame = true;
		bNotifiedTeleport = false;
		PhysComp.Disable(this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (HazeOwningActor == nullptr)
			return;

		// if (DestinationComp == nullptr)
		// 	DestinationComp = UBasicAIDestinationComponent::Get(HazeOwningActor);
		if (PhysComp == nullptr)
			PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		if (bNotifiedTeleport && bTeleportedThisFrame)
		{
			bTeleportedThisFrame = false;
			bPhysDisableTeleport = false;
		}

		bNotifiedTeleport = true;

		// if (CurrentFeatureTag == DarkPortalCompanionAnimTags::LaunchStart)
		// 	LocomotionState = EDarkPortalCompanionLocomotionState::LaunchStart;
		// else if (CurrentFeatureTag == DarkPortalCompanionAnimTags::Launch)
		// 	LocomotionState = EDarkPortalCompanionLocomotionState::Launching;
		// else if (CurrentFeatureTag == DarkPortalCompanionAnimTags::LaunchAttached)
		// 	LocomotionState = EDarkPortalCompanionLocomotionState::LaunchAttached;
		// else if (CurrentFeatureTag == DarkPortalCompanionAnimTags::PortalExit)
		// 	LocomotionState = EDarkPortalCompanionLocomotionState::PortalExit;
		// else if (CurrentFeatureTag == DarkPortalCompanionAnimTags::TeleportToPlayer)
		// 	LocomotionState = EDarkPortalCompanionLocomotionState::TeleportToPlayer;
		// else
		// 	LocomotionState = EDarkPortalCompanionLocomotionState::Follow;

		bIsFollowing = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::Follow);
		bIsIntroStart = IsCurrentFeatureTag(LightBirdCompanionAnimTags::IntroStart);
		bIsIntroReachPlayer = IsCurrentFeatureTag(LightBirdCompanionAnimTags::IntroReachPlayer);
		bIsLaunching = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::Launch);
		bIsLaunchStart = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::LaunchStart);
		bIsLaunchStartAttach = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::LaunchStartAttach);
		bIsLaunchAttached = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::LaunchAttached);
		bIsLaunchBlocked = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::LaunchBlocked);
		bPortalExit = IsCurrentFeatureTag(DarkPortalCompanionAnimTags::PortalExit);

		// if (MovementSpeed > 5)
		// 	PhysComp.Disable();
		// else if (!bTeleportedThisFrame)
		// 	PhysComp.ApplyProfileAsset(PhysProf);

		bool bPortalActive = (LocomotionState == EDarkPortalCompanionLocomotionState::LaunchAttached);

		if (bIsLaunchStart)
		{
			TwistAlpha = 0;
			CurlAlpha = 0;
		}
		else
		{
			TwistAlpha = 1;
			CurlAlpha = 1;
		}

		if (bPortalExit || bIsLaunching)
		{
			TrailAlpha = 1;
		}
		else if (Speed > 400)
		{
			TrailAlpha = (Speed / 600) / 10;
		}
		else
		{
			TrailAlpha = 0;
		}

		if (SpeedForward > 500)
		{
			DashPlayRate = SpeedForward / 600.0;
			TwistAlpha = 0;
		}
		else
		{
			DashPlayRate = 1;
			TwistAlpha = 1;
		}

		LocalVelocity = FVector(SpeedForward, SpeedRight, SpeedUp);
		Speed = LocalVelocity.Size();

		MovementSpeed = Speed / 600;

		DashSpeed = SpeedForward / 800;

		DashPlayRate = Math::Clamp(DashPlayRate, 1.0, 2.0);

		LocomotionPlayRate = FVector(SpeedForward, SpeedRight, SpeedUp).Size() / 300 * 1.0 + 0.3;
		LocomotionPlayRate = Math::Clamp(LocomotionPlayRate, 0.5, 3.0);

		CurlAlpha = 1.0 - (Speed / 600.0);
		CurlAlpha = Math::Clamp(CurlAlpha, 0.0, 1.0);

		bWantsToMove = !LocalVelocity.IsNearlyZero(40.0);

		FRotator DeltaRotation = (HazeOwningActor.ActorRotation - CachedActorRotation).Normalized;
		CachedActorRotation = HazeOwningActor.ActorRotation;

		// Calculate the hips rotation
		CalculateHipRotation(DeltaTime, DeltaRotation.Yaw);

		// Additive Banking
		if (bWantsToMove && AdditiveBankingAlpha != 1)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 1, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED);
		else if (!bWantsToMove && Speed < 50 && AdditiveBankingAlpha != 0)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 0, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED * 0.5);

		if (Math::Abs(RotationRate.X) > SMALL_NUMBER && DeltaTime > KINDA_SMALL_NUMBER)
		{
			DeltaYaw = Math::Clamp((Math::FInterpTo(DeltaYaw, DeltaRotation.Yaw / DeltaTime / 60.0, DeltaTime, 8)), -1, 1);
		}
		else
		{
			DeltaYaw = Math::Clamp((Math::FInterpTo(DeltaYaw, 0, DeltaTime, 8)), -1, 1);
		}

		const float UpDownRatio = HipsRotation.Pitch / 90;
		UpperBodyAdditiveBankingValues.Y = UpDownRatio;
		LowerBodyAdditiveBankingValues.Y = UpDownRatio;
		TailAdditiveBankingValues.Y = UpDownRatio;

		float TurnValueMultiplier = bRotatingIntoTurn ? 1 : 2;

		if (bRotatingIntoTurn)
		{
			HeadRollSpring.SpringTo(DeltaYaw, 30, 0.7, DeltaTime * TurnValueMultiplier);

			UpperBodyRollSpring.SpringTo(DeltaYaw, 20, 0.5, DeltaTime);

			LowerBodyRollSpring.SpringTo(DeltaYaw, 30, 0.3, DeltaTime);

			TailRollSpring.SpringTo(Math::Clamp(LowerBodyRollSpring.Value, -1.0, 1.0), 10, 0.2, DeltaTime);
		}
		else
		{
			HeadRollSpring.SpringTo(DeltaYaw, 50, 0.7, DeltaTime * TurnValueMultiplier);

			UpperBodyRollSpring.SpringTo(DeltaYaw, 30, 0.5, DeltaTime);

			LowerBodyRollSpring.SpringTo(DeltaYaw, 80, 0.3, DeltaTime);

			TailRollSpring.SpringTo(Math::Clamp(LowerBodyRollSpring.Value, -1.0, 1.0), 20, 0.2, DeltaTime);
		}

		UpperBodyAdditiveBankingValues.X = UpperBodyRollSpring.Value;

		LowerBodyAdditiveBankingValues.X = LowerBodyRollSpring.Value;

		TailAdditiveBankingValues.X = TailRollSpring.Value;

		HeadAdditiveBankingValues.X = HeadRollSpring.Value;

		// End Additive Banking

		if (bWantsToMove == false)
		{
			NoInputTimer = Math::FInterpTo(NoInputTimer, 1.0, DeltaTime, 0.25);
		}
		else
		{
			NoInputTimer = 0;
		}

		if (ShouldPhysicsBeEnabled(bPortalActive))
			PhysComp.ClearDisable(this);
		else
			PhysComp.Disable(this);

#if EDITOR

		/*
		Print("TrailAlpha: " + TrailAlpha, 0.f); // Emils Print
		Print("CurrentFeatureTag: " + CurrentFeatureTag, 0.f); // Emils Print
		Print("CurlAlpha: " + CurlAlpha, 0.f); // Emils Print
		Print("TwistAlpha: " + TwistAlpha, 0.f);
		Print("bIsAiming: " + bIsAiming, 0.f);

		Print("SpeedForward: " + SpeedForward, 0.f); // Emils Print
		Print("DashPlayRate: " + DashPlayRate, 0.f); // Emils Print
		Print("LocomotionPlayRate: " + LocomotionPlayRate, 0.f); // Emils Print

		Print("MovementSpeed: " + MovementSpeed, 0.f);
		Debug::DrawDebugSphere(HazeOwningActor.ActorForwardVector * 50 + DestinationComp.Destination, 10);
		Print("SwimmingAnimData.WantedDirection: " + SwimmingAnimData.WantedDirection, 0.f); // Emils Print
		Print("HipsRotation: " + HipsRotation, 0.f);
		Print("LowerBodyAdditiveBankingValues: " + LowerBodyAdditiveBankingValues, 0.f); // Emils Print

		if (HazeOwningActor.bHazeEditorOnlyDebugBool)
		{
		}
		*/
#endif
	}

	bool ShouldPhysicsBeEnabled(bool bPortalActive)
	{
		if (Speed > 1500)
			return false;

		if (bIsLaunchStart || bPortalActive || bPhysDisableTeleport)
			return false;

		return true;
	}

	/**
	 * Calcualte the hips rotation based on the players velocity
	 */
	void CalculateHipRotation(float DeltaTime, float YawDelta)
	{
		// Calculate Pitch (Up / Down)
		float PitchTarget;
		float PitchInterpSpeed;

		// Use different interp speeds depending if the companion is moving or returning back to Mh
		if (bWantsToMove)
		{
			PitchTarget = Math::Clamp(FRotator::MakeFromXZ(LocalVelocity, FVector::UpVector).Pitch, HIP_PITCH_MIN, HIP_PITCH_MAX);
			PitchInterpSpeed = HIP_PITCH_INTERPSPEED_SWIMMING;
		}
		else
		{
			// Companion is about to go back to Mh
			PitchTarget = 0;
			PitchInterpSpeed = HIP_PITCH_INTERPSPEED_STOP;
		}

		// Interpolate the rotation
		const float NewRotation = Math::FInterpTo(HipsRotation.Pitch, PitchTarget, DeltaTime, PitchInterpSpeed);

		// Update the rotation rate
		if (DeltaTime > 0.0)
			RotationRate.Y = Math::Clamp(((NewRotation - HipsRotation.Pitch) / DeltaTime / 100), -1.0, 1.0);

		HipsRotation.Pitch = NewRotation;

		HeadPitchSpring.SpringTo(RotationRate.Y, 30, 0.9, DeltaTime);

		UpperBodyPitchSpring.SpringTo(RotationRate.Y, 15, 0.5, DeltaTime);

		LowerBodyPitchSpring.SpringTo(RotationRate.Y, 10, 0.3, DeltaTime);

		TailPitchSpring.SpringTo(LowerBodyAdditivePitchValues.Y, 10, 0.2, DeltaTime);

		HeadAdditivePitchValues.Y = HeadPitchSpring.Value;

		UpperBodyAdditivePitchValues.Y = UpperBodyPitchSpring.Value;

		LowerBodyAdditivePitchValues.Y = LowerBodyPitchSpring.Value;

		TailAdditivePitchValues.Y = TailPitchSpring.Value;

		// Calculate the rotation rate
		float YawVelocity = (DeltaTime > 0.0) ? FRotator::NormalizeAxis(YawDelta) / DeltaTime : 0.0;
		const float YawTargetRotationRate = Math::Clamp(YawVelocity / 200.0, -1.0, 1.0);

		// Use different interp speeds depending if we're going into our out of a turn
		bRotatingIntoTurn = (Math::Abs(RotationRate.X) < Math::Abs(YawTargetRotationRate));

		float YawInterpSpeed = 104.5; // Going out of a turn
		// if (Math::Abs (RotationRate.X) < Math::Abs(YawTargetRotationRate))
		if (bRotatingIntoTurn)
			YawInterpSpeed = 7.5; // Leaning into a turn

		// Update the rotation rate
		RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);

		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, 5);
	}
}
