UCLASS(Abstract)
class UFeatureAnimInstanceTailAdultAirSmash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTailAdultAirSmash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTailAdultAirSmashAnimData AnimData;

	// Add Custom Variables Here

	//Components

	AAdultDragon AdultDragon;

	UPlayerAdultDragonComponent DragonComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialBankingInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SmashRollValue;

	float MAXROLLINTERPSPEED = 10;

	float RollMultiplier; 

	float ROLLRATE = 1600;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RollDirection;

	float SmashRollValueTarget;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeAcceleratedFloat AdditiveExitValue;

	float InitialAirSmashRollValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReset;

	float AirSmashRollDamping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Pitch;

	FHazeAcceleratedFloat LegsRollSpring;

	FHazeAcceleratedFloat TailRollSpring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D LegsAdditiveValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D TailAdditiveValues;

	FRotator CachedActorRotation;

	FRotator DeltaRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float  DeltaRoll;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Roll;

	float AdditiveExitValueTarget;

	EAdultDragonAnimationState CurrentState;

	UAdultDragonStrafeComponent StormStrafeComp;

	EAdultDragonStormStrafeState StrafeState;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTailAdultAirSmash NewFeature = GetFeatureAsClass(ULocomotionFeatureTailAdultAirSmash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		AdultDragon = Cast<AAdultDragon>(HazeOwningActor);
		if(AdultDragon == nullptr)
			AdultDragon = Cast<AAdultDragon>(HazeOwningActor.AttachParentActor);

		DragonComp = AdultDragon.DragonComponent;
		StormStrafeComp = UAdultDragonStrafeComponent::Get(DragonComp.Owner);

		if (PrevLocomotionAnimationTag == "AdultDragonStrafe")
		{
			InitialBankingInput = StormStrafeComp.Input.X;
		}

		else 

		{
			InitialBankingInput = DragonComp.AnimParams.Banking;
		} 

		RollMultiplier = 0;

		SmashRollValue.Roll = 0;

		RollDirection = InitialBankingInput < 0 ? -1 : 1;

		SmashRollValueTarget = DragonComp.AnimParams.AnimAirSmashRoll.Value;

		InitialAirSmashRollValue = DragonComp.AnimParams.AnimAirSmashRoll.Value;

	
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
		
		Pitch = AdultDragon.ActorRotation.Pitch;

		Roll = Math::FInterpTo(Roll, DragonComp.AnimParams.Banking * 60, DeltaTime, 1);

		if (DragonComp.StormState == EAdultDragonStormState::StormLoop)
			StrafeState = StormStrafeComp.AnimationState.Get();
		else
			CurrentState = DragonComp.AnimationState.Get();

		// FRotator DeltaRotation = (AdultDragon.ActorRotation - CachedActorRotation).Normalized;
	
		// CachedActorRotation = AdultDragon.ActorRotation;

		// DeltaRoll = DeltaRotation.Yaw /60;

		
		if (CheckValueChangedAndSetBool(bPlayExit, LocomotionAnimationTag != Feature.Tag, EHazeCheckBooleanChangedDirection::FalseToTrue)) 
		{
			
			float DampingMinValue = 0.5;

			if (RollDirection > 0)
			{
				SmashRollValueTarget = Math::CeilToFloat(DragonComp.AnimParams.AnimAirSmashRoll.Value / 360) * 360;
				AirSmashRollDamping = (DragonComp.AnimParams.AnimAirSmashRoll.Value / 360) - Math::FloorToFloat(DragonComp.AnimParams.AnimAirSmashRoll.Value / 360);
				AirSmashRollDamping = AirSmashRollDamping * (1 - DampingMinValue) + DampingMinValue;
				
			}
			else 
			{
				SmashRollValueTarget = Math::FloorToFloat(DragonComp.AnimParams.AnimAirSmashRoll.Value / 360) * 360;
				AirSmashRollDamping = Math::CeilToFloat(DragonComp.AnimParams.AnimAirSmashRoll.Value / 360) - (DragonComp.AnimParams.AnimAirSmashRoll.Value / 360);
				AirSmashRollDamping = AirSmashRollDamping * (1 - DampingMinValue) + DampingMinValue;
				
			}
		
			AdditiveExitValueTarget = Math::Wrap(SmashRollValue.Roll / 360, 0, 1);
				
			if (RollDirection < 0)
			{ 
				AdditiveExitValueTarget = -(1- AdditiveExitValueTarget);
			}
				
			AdditiveExitValue.SnapTo(AdditiveExitValueTarget);

		}

		if (bPlayExit && (AdditiveExitValueTarget > 0.8 || AdditiveExitValueTarget < -0.8))
		{
			DragonComp.AnimParams.AnimAirSmashRoll.SpringTo(SmashRollValueTarget, 45, AirSmashRollDamping, DeltaTime);
		}

		else if (bPlayExit)
		{
			DragonComp.AnimParams.AnimAirSmashRoll.SpringTo(SmashRollValueTarget, 36, AirSmashRollDamping, DeltaTime);
		}

		else
		{
			RollMultiplier = Math::FInterpTo(RollMultiplier, 1, DeltaTime, 5);
			SmashRollValueTarget += DeltaTime * ROLLRATE * RollMultiplier * RollDirection;
			DragonComp.AnimParams.AnimAirSmashRoll.AccelerateTo(SmashRollValueTarget, 0.5, DeltaTime);
		}		

		SmashRollValue.Roll = DragonComp.AnimParams.AnimAirSmashRoll.Value;
	
		AdditiveExitValue.SpringTo(0, 8, 0.2, DeltaTime);
		LegsRollSpring.SpringTo(AdditiveExitValue.Value, 30, 0.5, DeltaTime);

		TailRollSpring.SpringTo(AdditiveExitValue.Value, 20, 0.2, DeltaTime);

		LegsAdditiveValues.X = LegsRollSpring.Value;

		TailAdditiveValues.X = TailRollSpring.Value;

		
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
				
		// Implement Custom Stuff Here

		if (TopLevelGraphRelevantStateName == "Exit"  && IsLowestLevelGraphRelevantAnimFinished())
		{
			return true;
		}

		else if (TopLevelGraphRelevantStateName == "Exit" && LowestLevelGraphRelevantAnimTimeRemainingFraction < 0.2 && CurrentState != EAdultDragonAnimationState::Flying && StrafeState != EAdultDragonStormStrafeState::Flying)
		{
			return true;
		}

		else if (TopLevelGraphRelevantStateName == "Exit" && LowestLevelGraphRelevantAnimTimeRemainingFraction < 0.8 && CurrentState == EAdultDragonAnimationState::Dash)
		{
			return true;
		}

		else if (TopLevelGraphRelevantStateName == "Exit" && LowestLevelGraphRelevantAnimTimeRemainingFraction < 0.8 && StrafeState == EAdultDragonStormStrafeState::Dash)
		{
			return true;
		}


		else

		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		// if (LocomotionAnimationTag == n"AdultDragonFlying")
	 	// {
			SetAnimFloatParam (n"DragonAirSmashRollFloatTarget", SmashRollValueTarget);
			SetAnimFloatParam (n"DragonAirSmashRollDirectionFloat", RollDirection);
			SetAnimFloatParam (n"DragonAirSmashDampingFloat", AirSmashRollDamping);
			SetAnimBoolParam (n"SkipStart", true,);
		//}
	}

}
